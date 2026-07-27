import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/scale_models.dart';
import '../domain/scale_parser.dart';

class SimulatedScaleAdapter implements ScaleAdapter {
  final _controller = StreamController<ScaleReading>.broadcast();
  Timer? _timer;
  double _weight = 0;
  bool _stable = true;
  String _unit = 'kg';
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;

  @override
  Stream<ScaleReading> get readings => _controller.stream;

  @override
  ScaleConnectionStatus get status => _status;

  @override
  Future<void> connect() async {
    _status = ScaleConnectionStatus.connected;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _emit());
  }

  @override
  Future<void> disconnect() async {
    _status = ScaleConnectionStatus.disconnected;
    _timer?.cancel();
  }

  @override
  Future<List<String>> discoverDevices() async => const ['SIMULATED_SCALE'];

  @override
  Future<void> tare() async => setExactWeight(0);

  @override
  Future<void> zero() async => setExactWeight(0);

  void setExactWeight(double value, {bool stable = true, String unit = 'kg'}) {
    _weight = value;
    _stable = stable;
    _unit = unit;
    _emit();
  }

  void increase([double step = 0.1]) =>
      setExactWeight(_weight + step, stable: false, unit: _unit);

  void decrease([double step = 0.1]) => setExactWeight(
    (_weight - step).clamp(0, double.infinity),
    stable: false,
    unit: _unit,
  );

  void placeItem(double weight) =>
      setExactWeight(weight, stable: false, unit: _unit);

  void removeItem() => setExactWeight(0, stable: true, unit: _unit);

  void markStable(bool stable) {
    _stable = stable;
    _emit();
  }

  void changeUnit(String unit) {
    _unit = unit;
    _emit();
  }

  void _emit() {
    if (_status != ScaleConnectionStatus.connected) return;
    _controller.add(
      ScaleReading(
        grossWeight: _weight,
        unit: _unit,
        isStable: _stable,
        raw: 'SIM,${_stable ? 'ST' : 'US'},${_weight.toStringAsFixed(3)}$_unit',
        recordedAt: DateTime.now(),
      ),
    );
    if (!_stable) {
      _stable = true;
    }
  }
}

class BluetoothScaleAdapter implements ScaleAdapter {
  BluetoothScaleAdapter({
    required this.transport,
    required this.profile,
    this.deviceId,
  }) : _buffer = ScalePacketBuffer(profile),
       _parser = ScaleReadingParser(profile);

  final BluetoothTransport transport;
  final ScaleParsingProfile profile;
  final String? deviceId;
  final ScalePacketBuffer _buffer;
  final ScaleReadingParser _parser;
  final _controller = StreamController<ScaleReading>.broadcast();
  final _statusController = StreamController<ScaleConnectionStatus>.broadcast();
  final _rawController = StreamController<String>.broadcast();
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<ScaleConnectionStatus>? _transportStatusSubscription;
  StreamSubscription<String>? _rawSubscription;
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;
  bool _explicitDisconnect = false;
  Timer? _noDataTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _connectInProgress = false;

  @override
  Stream<ScaleReading> get readings => _controller.stream;

  Stream<ScaleConnectionStatus> get statusStream => _statusController.stream;

  Stream<String> get rawDataStream => _rawController.stream;

  @override
  ScaleConnectionStatus get status => _status;

  @override
  Future<void> connect() async {
    if (_status == ScaleConnectionStatus.connected ||
        _status == ScaleConnectionStatus.connecting ||
        _status == ScaleConnectionStatus.receiving ||
        _connectInProgress) {
      return;
    }
    _connectInProgress = true;
    _reconnectTimer?.cancel();
    _explicitDisconnect = false;
    _status = ScaleConnectionStatus.connecting;
    _statusController.add(_status);
    try {
      final devices = await discoverDevices();
      final target = deviceId ?? devices.firstOrNull;
      if (target == null) {
        _status = ScaleConnectionStatus.failed;
        _statusController.add(_status);
        return;
      }
      await transport.connect(target);
    } catch (_) {
      _status = transport.status == ScaleConnectionStatus.disabled
          ? ScaleConnectionStatus.disabled
          : ScaleConnectionStatus.error;
      _statusController.add(_status);
      _scheduleReconnect();
      return;
    } finally {
      _connectInProgress = false;
    }
    _transportStatusSubscription?.cancel();
    _rawSubscription?.cancel();
    _transportStatusSubscription = transport.statusStream.listen((status) {
      _status = status;
      _statusController.add(status);
      if ((status == ScaleConnectionStatus.error ||
              status == ScaleConnectionStatus.disconnected) &&
          !_explicitDisconnect) {
        _scheduleReconnect();
      }
    });
    _rawSubscription = transport.rawDataStream.listen(_rawController.add);
    _subscription?.cancel();
    _subscription = transport.byteStream.listen(
      _handleChunk,
      onError: (_) {
        _status = ScaleConnectionStatus.error;
        _statusController.add(_status);
        _scheduleReconnect();
      },
      onDone: _scheduleReconnect,
    );
    _status = ScaleConnectionStatus.connected;
    _statusController.add(_status);
    _armNoDataTimeout();
  }

  @override
  Future<void> disconnect() async {
    _explicitDisconnect = true;
    _noDataTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    await _transportStatusSubscription?.cancel();
    await _rawSubscription?.cancel();
    await transport.disconnect();
    _status = ScaleConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  @override
  Future<List<String>> discoverDevices() => transport.discoverDevices();

  @override
  Future<void> tare() async {}

  @override
  Future<void> zero() async {}

  void _handleChunk(List<int> chunk) {
    _armNoDataTimeout();
    for (final packet in _buffer.addBytes(chunk)) {
      final reading = _parser.parse(packet);
      if (reading != null) {
        _reconnectAttempt = 0;
        _status = ScaleConnectionStatus.receiving;
        _statusController.add(_status);
        _controller.add(
          ScaleReading(
            grossWeight: reading.grossWeight,
            unit: reading.unit,
            isStable: reading.isStable,
            raw: reading.raw,
            recordedAt: reading.recordedAt,
            deviceId: deviceId,
            profileId: profile.id,
          ),
        );
      }
    }
  }

  void _armNoDataTimeout() {
    _noDataTimer?.cancel();
    _noDataTimer = Timer(const Duration(seconds: 5), () {
      if (_status == ScaleConnectionStatus.connected ||
          _status == ScaleConnectionStatus.receiving) {
        _status = ScaleConnectionStatus.error;
        _statusController.add(_status);
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    if (_explicitDisconnect ||
        deviceId == null ||
        _reconnectTimer?.isActive == true ||
        _connectInProgress) {
      return;
    }
    _reconnectAttempt += 1;
    final delayMs = (500 * (1 << (_reconnectAttempt - 1))).clamp(500, 10000);
    _status = ScaleConnectionStatus.reconnecting;
    _statusController.add(_status);
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      _reconnectTimer = null;
      if (_explicitDisconnect) return;
      _noDataTimer?.cancel();
      await _subscription?.cancel();
      await _transportStatusSubscription?.cancel();
      await _rawSubscription?.cancel();
      await transport.disconnect();
      _explicitDisconnect = false;
      await connect();
    });
  }
}

class InMemoryBluetoothTransport implements BluetoothTransport {
  final _controller = StreamController<List<int>>.broadcast();
  final _statusController = StreamController<ScaleConnectionStatus>.broadcast();
  final _rawController = StreamController<String>.broadcast();
  bool connected = false;
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;

  @override
  Stream<List<int>> get byteStream => _controller.stream;

  @override
  Stream<ScaleConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get rawDataStream => _rawController.stream;

  @override
  ScaleConnectionStatus get status => _status;

  @override
  Future<bool> isEnabled() async => true;

  @override
  Future<bool> requestEnable() async => true;

  @override
  Future<void> connect(String deviceId) async {
    connected = true;
    _status = ScaleConnectionStatus.connected;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    _status = ScaleConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  @override
  Future<List<ScaleDevice>> pairedDevices() async => const [
    ScaleDevice(
      id: 'SIMULATED_SCALE',
      name: 'Simulated Scale',
      transportType: ScaleTransportType.simulator,
      isPaired: true,
    ),
  ];

  @override
  Future<List<ScaleDevice>> scanDevices({Duration? timeout}) => pairedDevices();

  @override
  Future<List<String>> discoverDevices() async => const [
    'POC_CLASSIC_SPP_SCALE',
  ];

  void emitAscii(String packet) {
    _rawController.add(packet);
    _controller.add(ascii.encode(packet));
  }
}

class ClassicSppTransport implements BluetoothTransport {
  ClassicSppTransport({FlutterClassicBluetooth? bluetooth})
    : _bluetooth = bluetooth ?? FlutterClassicBluetooth();

  final FlutterClassicBluetooth _bluetooth;
  final _bytesController = StreamController<List<int>>.broadcast();
  final _statusController = StreamController<ScaleConnectionStatus>.broadcast();
  final _rawController = StreamController<String>.broadcast();
  StreamSubscription<Uint8List>? _inputSubscription;
  StreamSubscription<BtcConnectionState>? _connectionStateSubscription;
  BtcConnection? _connection;
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;

  @override
  Stream<List<int>> get byteStream => _bytesController.stream;

  @override
  Stream<ScaleConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get rawDataStream => _rawController.stream;

  @override
  ScaleConnectionStatus get status => _status;

  @override
  Future<bool> isEnabled() => _bluetooth.isEnabled();

  @override
  Future<bool> requestEnable() => _bluetooth.enableBluetooth();

  Future<bool> requestPermissions() async {
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    return connect.isGranted && scan.isGranted;
  }

  @override
  Future<List<ScaleDevice>> pairedDevices() async {
    final granted = await requestPermissions();
    if (!granted) {
      _setStatus(ScaleConnectionStatus.permissionRequired);
      return const [];
    }
    if (!await _bluetooth.isEnabled()) {
      _setStatus(ScaleConnectionStatus.disabled);
      return const [];
    }
    final devices = await _bluetooth.getPairedDevices();
    return devices.map(_mapDevice).toList();
  }

  @override
  Future<List<ScaleDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final granted = await requestPermissions();
    if (!granted) {
      _setStatus(ScaleConnectionStatus.permissionRequired);
      return const [];
    }
    if (!await _bluetooth.isEnabled()) {
      _setStatus(ScaleConnectionStatus.disabled);
      return const [];
    }

    final found = <String, ScaleDevice>{};
    _setStatus(ScaleConnectionStatus.discovering);
    final subscription = _bluetooth.discoveryResults.listen((device) {
      final mapped = _mapDevice(device);
      found[mapped.id] = mapped;
    });
    try {
      await _bluetooth.startDiscovery();
      await Future<void>.delayed(timeout);
      await _bluetooth.stopDiscovery();
    } finally {
      await subscription.cancel();
    }
    _setStatus(ScaleConnectionStatus.disconnected);
    return found.values.toList();
  }

  @override
  Future<List<String>> discoverDevices() async =>
      (await pairedDevices()).map((device) => device.id).toList();

  @override
  Future<void> connect(String deviceId) async {
    final granted = await requestPermissions();
    if (!granted) {
      _setStatus(ScaleConnectionStatus.permissionRequired);
      throw StateError('Bluetooth permission required');
    }
    if (!await _bluetooth.isEnabled()) {
      _setStatus(ScaleConnectionStatus.disabled);
      throw StateError('Bluetooth disabled');
    }

    await disconnect();
    _setStatus(ScaleConnectionStatus.connecting);
    try {
      _connection = await _bluetooth.connect(
        address: deviceId,
        uuid: BtcUuid.spp,
        secure: true,
        timeout: const Duration(seconds: 15),
      );
    } catch (_) {
      await disconnect();
      _setStatus(ScaleConnectionStatus.connecting);
      _connection = await _bluetooth.connect(
        address: deviceId,
        uuid: BtcUuid.spp,
        secure: false,
        timeout: const Duration(seconds: 15),
      );
    }
    _connectionStateSubscription = _connection!.stateStream.listen((state) {
      switch (state) {
        case BtcConnectionState.connecting:
          _setStatus(ScaleConnectionStatus.connecting);
        case BtcConnectionState.connected:
          _setStatus(ScaleConnectionStatus.connected);
        case BtcConnectionState.disconnecting:
          _setStatus(ScaleConnectionStatus.disconnected);
        case BtcConnectionState.disconnected:
          _setStatus(ScaleConnectionStatus.disconnected);
      }
    });
    _inputSubscription = _connection!.input.listen(
      (bytes) {
        _rawController.add(ascii.decode(bytes, allowInvalid: true));
        _bytesController.add(bytes);
        _setStatus(ScaleConnectionStatus.receiving);
      },
      onError: (_) => _setStatus(ScaleConnectionStatus.error),
      onDone: () => _setStatus(ScaleConnectionStatus.disconnected),
    );
    _setStatus(ScaleConnectionStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    await _inputSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await _connection?.close();
    _connection?.dispose();
    _connection = null;
    _setStatus(ScaleConnectionStatus.disconnected);
  }

  ScaleDevice _mapDevice(BtcDevice device) => ScaleDevice(
    id: device.address,
    name: device.displayName,
    address: device.address,
    transportType: ScaleTransportType.classicSpp,
    isPaired: device.bondState == BtcBondState.bonded,
    rssi: device.rssi,
  );

  void _setStatus(ScaleConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }
}

class ScaleConnectionManager {
  ScaleConnectionManager({
    required this.transport,
    required this.profile,
    this._preferences,
  });

  static const _deviceKey = 'scale.device';
  static const _profileKey = 'scale.profile';
  static const _autoReconnectKey = 'scale.autoReconnect';

  final BluetoothTransport transport;
  final ScaleParsingProfile profile;
  SharedPreferences? _preferences;
  BluetoothScaleAdapter? _adapter;

  BluetoothScaleAdapter? get adapter => _adapter;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<ScaleDevice?> savedDevice() async {
    final raw = (await _prefs).getString(_deviceKey);
    if (raw == null) return null;
    return ScaleDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ScaleParsingProfile> savedProfile() async {
    final raw = (await _prefs).getString(_profileKey);
    if (raw == null) return profile;
    return ScaleParsingProfile.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<bool> autoReconnect() async =>
      (await _prefs).getBool(_autoReconnectKey) ?? true;

  Future<void> save({
    required ScaleDevice device,
    required ScaleParsingProfile profile,
    required bool autoReconnect,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_deviceKey, jsonEncode(device.toJson()));
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await prefs.setBool(_autoReconnectKey, autoReconnect);
  }

  Future<void> forget() async {
    final prefs = await _prefs;
    await prefs.remove(_deviceKey);
    await prefs.remove(_profileKey);
    await prefs.remove(_autoReconnectKey);
  }

  Future<BluetoothScaleAdapter> connectSaved() async {
    final device = await savedDevice();
    final saved = await savedProfile();
    if (device == null) {
      throw StateError('No saved scale device');
    }
    final adapter = BluetoothScaleAdapter(
      transport: transport,
      profile: saved,
      deviceId: device.id,
    );
    _adapter = adapter;
    await adapter.connect();
    return adapter;
  }
}
