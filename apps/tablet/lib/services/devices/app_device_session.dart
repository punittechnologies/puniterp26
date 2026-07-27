import 'dart:async';

import '../../features/weighing/data/scale_adapters.dart';
import '../../features/weighing/domain/scale_models.dart';
import 'bluetooth_thermal_printer_adapter.dart';

/// Process-wide hardware session used by the Web Label edition.
///
/// Screens subscribe to these broadcast streams, but navigation never owns or
/// disconnects the underlying scale/printer connections.
class AppDeviceSession {
  AppDeviceSession._();

  static final AppDeviceSession instance = AppDeviceSession._();

  static const _defaultProfile = ScaleParsingProfile(
    id: 'comma-st-gs',
    name: 'Comma ST/US + weight + unit',
    exampleRaw: 'ST,GS,+0012.340kg\n',
    stableTokens: ['ST'],
    unstableTokens: ['US'],
  );

  final BluetoothThermalPrinterAdapter printerAdapter =
      BluetoothThermalPrinterAdapter();
  final ClassicSppTransport scaleTransport = ClassicSppTransport();
  late final ScaleConnectionManager scaleManager = ScaleConnectionManager(
    transport: scaleTransport,
    profile: _defaultProfile,
  );

  final _readings = StreamController<ScaleReading>.broadcast();
  final _statuses = StreamController<ScaleConnectionStatus>.broadcast();
  final _rawData = StreamController<String>.broadcast();

  BluetoothScaleAdapter? _scaleAdapter;
  StreamSubscription<ScaleReading>? _readingSubscription;
  StreamSubscription<ScaleConnectionStatus>? _statusSubscription;
  StreamSubscription<String>? _rawSubscription;
  Future<void>? _refreshFuture;

  Stream<ScaleReading> get readings => _readings.stream;
  Stream<ScaleConnectionStatus> get scaleStatuses => _statuses.stream;
  Stream<String> get rawScaleData => _rawData.stream;
  BluetoothScaleAdapter? get scaleAdapter => _scaleAdapter;
  ScaleConnectionStatus get scaleStatus =>
      _scaleAdapter?.status ?? ScaleConnectionStatus.disconnected;

  Future<BluetoothScaleAdapter?> connectSavedScale() async {
    final saved = await scaleManager.savedDevice();
    if (saved == null || !await scaleManager.autoReconnect()) return null;
    final profile = await scaleManager.savedProfile();
    return connectScale(
      device: saved,
      profile: profile,
      autoReconnect: true,
      saveSelection: false,
    );
  }

  Future<BluetoothScaleAdapter> connectScale({
    required ScaleDevice device,
    required ScaleParsingProfile profile,
    required bool autoReconnect,
    bool saveSelection = true,
  }) async {
    final current = _scaleAdapter;
    if (current != null &&
        current.deviceId == device.id &&
        current.profile.id == profile.id &&
        (current.status == ScaleConnectionStatus.connected ||
            current.status == ScaleConnectionStatus.receiving ||
            current.status == ScaleConnectionStatus.connecting)) {
      if (saveSelection) {
        await scaleManager.save(
          device: device,
          profile: profile,
          autoReconnect: autoReconnect,
        );
      }
      return current;
    }

    await _detachScale(disconnect: true);
    final adapter = BluetoothScaleAdapter(
      transport: scaleTransport,
      profile: profile,
      deviceId: device.id,
    );
    _scaleAdapter = adapter;
    _readingSubscription = adapter.readings.listen(_readings.add);
    _statusSubscription = adapter.statusStream.listen(_statuses.add);
    _rawSubscription = adapter.rawDataStream.listen(_rawData.add);
    if (saveSelection) {
      await scaleManager.save(
        device: device,
        profile: profile,
        autoReconnect: autoReconnect,
      );
    }
    await adapter.connect();
    _statuses.add(adapter.status);
    return adapter;
  }

  Future<void> disconnectScale() => _detachScale(disconnect: true);

  Future<void> forgetScale() async {
    await _detachScale(disconnect: true);
    await scaleManager.forget();
  }

  Future<void> refreshConnections() {
    final running = _refreshFuture;
    if (running != null) return running;
    final future = _refreshConnections();
    _refreshFuture = future;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    });
  }

  Future<void> _refreshConnections() async {
    final adapter = _scaleAdapter;
    if (adapter == null ||
        (adapter.status != ScaleConnectionStatus.connected &&
            adapter.status != ScaleConnectionStatus.receiving &&
            adapter.status != ScaleConnectionStatus.connecting)) {
      await connectSavedScale();
    }

    final printer = await printerAdapter.savedPrinter();
    if (printer != null && !await printerAdapter.isConnected()) {
      await printerAdapter.connect(printer.id);
    }
  }

  Future<void> _detachScale({required bool disconnect}) async {
    await _readingSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _rawSubscription?.cancel();
    _readingSubscription = null;
    _statusSubscription = null;
    _rawSubscription = null;
    final adapter = _scaleAdapter;
    _scaleAdapter = null;
    if (disconnect) await adapter?.disconnect();
    _statuses.add(ScaleConnectionStatus.disconnected);
  }
}
