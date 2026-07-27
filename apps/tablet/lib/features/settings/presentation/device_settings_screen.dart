import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_edition.dart';
import '../../../services/devices/app_device_session.dart';
import '../../weighing/data/scale_adapters.dart';
import '../../weighing/domain/scale_models.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen>
    with WidgetsBindingObserver {
  static const profiles = [
    ScaleParsingProfile(
      id: 'comma-st-gs',
      name: 'Comma ST/US + weight + unit',
      exampleRaw: 'ST,GS,+0012.340kg\n',
      stableTokens: ['ST'],
      unstableTokens: ['US'],
    ),
    ScaleParsingProfile(
      id: 'fixed-a12',
      name: 'Fixed length serial A&D style',
      fixedLength: 17,
      weightStart: 3,
      weightLength: 9,
      decimalPlaces: 3,
      stableTokens: ['ST'],
      unstableTokens: ['US'],
      exampleRaw: 'ST,+00012340kg\r\n',
    ),
    ScaleParsingProfile(
      id: 'regex-weight',
      name: 'Regex first numeric weight',
      regex: r'([+-]?\d+(?:\.\d+)?)',
      exampleRaw: 'S +12.340 kg\n',
      stableTokens: ['S'],
      unstableTokens: ['U'],
    ),
  ];

  late final ClassicSppTransport transport;
  late final ScaleConnectionManager manager;
  BluetoothScaleAdapter? adapter;
  StreamSubscription<ScaleReading>? readingSubscription;
  StreamSubscription<ScaleConnectionStatus>? statusSubscription;
  StreamSubscription<String>? rawSubscription;
  List<ScaleDevice> paired = [];
  List<ScaleDevice> discovered = [];
  ScaleDevice? selectedDevice;
  ScaleParsingProfile selectedProfile = profiles.first;
  ScaleReading? reading;
  ScaleConnectionStatus status = ScaleConnectionStatus.disconnected;
  bool autoReconnect = true;
  String rawLog = '';
  String message = 'Select a paired Classic SPP scale.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    transport = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.scaleTransport
        : ClassicSppTransport();
    manager = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.scaleManager
        : ScaleConnectionManager(
            transport: transport,
            profile: selectedProfile,
          );
    _loadSaved();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && autoReconnect) {
      _refreshPaired();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    readingSubscription?.cancel();
    statusSubscription?.cancel();
    rawSubscription?.cancel();
    if (!AppEdition.webManagedLabels) {
      adapter?.disconnect();
    }
    super.dispose();
  }

  Future<void> _loadSaved() async {
    selectedDevice = await manager.savedDevice();
    selectedProfile = await manager.savedProfile();
    autoReconnect = await manager.autoReconnect();
    await _refreshPaired();
    if (selectedDevice != null && autoReconnect) {
      await _connect();
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestPermissions() async {
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    setState(() {
      message = connect.isGranted && scan.isGranted
          ? 'Bluetooth permissions granted.'
          : 'Bluetooth permission required. Enable it from Android settings.';
    });
    if (connect.isPermanentlyDenied || scan.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _enableBluetooth() async {
    final enabled = await transport.requestEnable();
    setState(
      () => message = enabled ? 'Bluetooth enabled.' : 'Bluetooth is off.',
    );
  }

  Future<void> _refreshPaired() async {
    try {
      final devices = await transport.pairedDevices();
      setState(() {
        paired = devices;
        status = transport.status;
        message = devices.isEmpty
            ? 'No paired Classic SPP devices found. Pair the scale in Android Bluetooth settings first.'
            : 'Found ${devices.length} paired device(s).';
      });
    } catch (error) {
      setState(() => message = 'Could not list paired devices: $error');
    }
  }

  Future<void> _scan() async {
    try {
      setState(() => message = 'Scanning for Classic Bluetooth devices...');
      final devices = await transport.scanDevices();
      setState(() {
        discovered = devices;
        message = 'Scan complete: ${devices.length} device(s).';
      });
    } catch (error) {
      setState(() => message = 'Scan failed: $error');
    }
  }

  Future<void> _connect() async {
    final device = selectedDevice;
    if (device == null) {
      setState(() => message = 'Select a scale first.');
      return;
    }

    await _disconnect(silent: true);
    final next = AppEdition.webManagedLabels
        ? await AppDeviceSession.instance.connectScale(
            device: device,
            profile: selectedProfile,
            autoReconnect: autoReconnect,
          )
        : BluetoothScaleAdapter(
            transport: transport,
            profile: selectedProfile,
            deviceId: device.id,
          );
    adapter = next;
    final statusStream = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.scaleStatuses
        : next.statusStream;
    final rawStream = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.rawScaleData
        : next.rawDataStream;
    final readingStream = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.readings
        : next.readings;
    statusSubscription = statusStream.listen((value) {
      if (mounted) setState(() => status = value);
    });
    rawSubscription = rawStream.listen((value) {
      if (!mounted) return;
      setState(() {
        rawLog = '$value\n$rawLog';
        rawLog = rawLog.length > 2000 ? rawLog.substring(0, 2000) : rawLog;
      });
    });
    readingSubscription = readingStream.listen((value) {
      if (mounted) setState(() => reading = value);
    });

    try {
      if (!AppEdition.webManagedLabels) {
        await next.connect();
        await manager.save(
          device: device,
          profile: selectedProfile,
          autoReconnect: autoReconnect,
        );
      }
      setState(() => message = 'Connected to ${device.name}.');
    } catch (error) {
      setState(() => message = 'Connection failed: $error');
    }
  }

  Future<void> _disconnect({bool silent = false}) async {
    await readingSubscription?.cancel();
    await statusSubscription?.cancel();
    await rawSubscription?.cancel();
    if (AppEdition.webManagedLabels) {
      await AppDeviceSession.instance.disconnectScale();
    } else {
      await adapter?.disconnect();
    }
    adapter = null;
    if (!silent) {
      setState(() {
        status = ScaleConnectionStatus.disconnected;
        message = 'Disconnected.';
      });
    }
  }

  Future<void> _forget() async {
    await _disconnect(silent: true);
    if (AppEdition.webManagedLabels) {
      await AppDeviceSession.instance.forgetScale();
    } else {
      await manager.forget();
    }
    setState(() {
      selectedDevice = null;
      reading = null;
      rawLog = '';
      status = ScaleConnectionStatus.disconnected;
      message = 'Saved scale forgotten.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = [...paired, ...discovered]
        .fold<Map<String, ScaleDevice>>({}, (map, device) {
          map[device.id] = device;
          return map;
        })
        .values
        .toList();
    final selectedDeviceValue = devices.contains(selectedDevice)
        ? selectedDevice
        : null;
    final selectedProfileValue = profiles.contains(selectedProfile)
        ? selectedProfile
        : profiles.first;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Scale Settings & Diagnostics'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final controls = _controlPanel(
            devices,
            selectedDeviceValue,
            selectedProfileValue,
          );

          if (compact) {
            return ListView(
              padding: const EdgeInsets.all(14),
              children: [
                controls,
                const SizedBox(height: 14),
                SizedBox(height: 220, child: _readingPanel()),
                const SizedBox(height: 14),
                SizedBox(height: 260, child: _rawPanel()),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(width: 420, child: controls),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _readingPanel()),
                      const SizedBox(height: 16),
                      Expanded(child: _rawPanel()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _controlPanel(
    List<ScaleDevice> devices,
    ScaleDevice? selectedDeviceValue,
    ScaleParsingProfile selectedProfileValue,
  ) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statusCard(),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _requestPermissions,
              child: const Text('Request Permissions'),
            ),
            OutlinedButton(
              onPressed: _enableBluetooth,
              child: const Text('Enable Bluetooth'),
            ),
            OutlinedButton(
              onPressed: _refreshPaired,
              child: const Text('Paired Devices'),
            ),
            OutlinedButton(onPressed: _scan, child: const Text('Scan')),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ScaleDevice>(
          initialValue: selectedDeviceValue,
          decoration: const InputDecoration(
            labelText: 'Selected weighing scale',
            border: OutlineInputBorder(),
          ),
          items: devices
              .map(
                (device) => DropdownMenuItem(
                  value: device,
                  child: Text('${device.name}  ${device.address ?? ''}'),
                ),
              )
              .toList(),
          onChanged: (device) => setState(() => selectedDevice = device),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ScaleParsingProfile>(
          initialValue: selectedProfileValue,
          decoration: const InputDecoration(
            labelText: 'Parsing profile',
            border: OutlineInputBorder(),
          ),
          items: profiles
              .map(
                (profile) =>
                    DropdownMenuItem(value: profile, child: Text(profile.name)),
              )
              .toList(),
          onChanged: (profile) =>
              setState(() => selectedProfile = profile ?? profiles.first),
        ),
        SwitchListTile(
          value: autoReconnect,
          onChanged: (value) => setState(() => autoReconnect = value),
          title: const Text('Automatic reconnect'),
          subtitle: const Text(
            'Reconnect with bounded backoff after scale power loss.',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: selectedDevice == null ? null : _connect,
              child: const Text('Connect'),
            ),
            OutlinedButton(
              onPressed: adapter == null ? null : () => _disconnect(),
              child: const Text('Disconnect'),
            ),
            OutlinedButton(
              onPressed: selectedDevice == null ? null : _forget,
              child: const Text('Forget Scale'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'State: ${status.name}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message),
            if (selectedDevice != null)
              Text(
                'Saved scale: ${selectedDevice!.name} (${selectedDevice!.id})',
              ),
          ],
        ),
      ),
    );
  }

  Widget _readingPanel() {
    final value = reading;
    return Card(
      child: Center(
        child: value == null
            ? const Text('No live reading yet', style: TextStyle(fontSize: 36))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.grossWeight.toStringAsFixed(3),
                    style: const TextStyle(
                      fontSize: 86,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(value.unit, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(value.isStable ? 'Stable' : 'Unstable'),
                    backgroundColor: value.isStable
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _rawPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raw scale data',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  rawLog.isEmpty ? 'Waiting for bytes...' : rawLog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
