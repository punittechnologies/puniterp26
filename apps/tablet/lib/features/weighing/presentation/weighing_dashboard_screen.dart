import 'dart:async';
import 'dart:convert' show latin1;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_session.dart';
import '../../../core/config/app_edition.dart';
import '../../../core/database/local_database.dart';
import '../../../services/devices/android_bluetooth_settings.dart';
import '../../../services/devices/app_device_session.dart';
import '../../../services/devices/bluetooth_thermal_printer_adapter.dart';
import '../../../services/devices/printer_adapter.dart';
import '../../../services/sync/sync_queue_service.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../labels/data/label_template_repository.dart';
import '../../labels/domain/label_template_models.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product_models.dart';
import '../../verification/data/qr_verification_repository.dart';
import '../data/production_repository.dart';
import '../data/scale_adapters.dart';
import '../domain/scale_models.dart';
import '../domain/weighing_logic.dart';
import 'searchable_selection_field.dart';

class WeighingDashboardScreen extends StatefulWidget {
  const WeighingDashboardScreen({super.key});

  @override
  State<WeighingDashboardScreen> createState() =>
      _WeighingDashboardScreenState();
}

class WebBatchConfig {
  const WebBatchConfig({
    required this.id,
    required this.name,
    required this.products,
  });

  factory WebBatchConfig.fromJson(Map<String, dynamic> json) {
    final name =
        json['name'] ??
        json['batch_name'] ??
        json['batch'] ??
        json['title'] ??
        json['code'];
    final rawProducts =
        json['products'] ??
        json['items'] ??
        json['product_fields'] ??
        json['products_fields_values'] ??
        json['details'];

    return WebBatchConfig(
      id: json['id']?.toString() ?? name?.toString() ?? '',
      name: name?.toString().trim() ?? '',
      products: WebBatchProductConfig.fromCollection(rawProducts),
    );
  }

  final String id;
  final String name;
  final List<WebBatchProductConfig> products;
}

class WebBatchProductConfig {
  const WebBatchProductConfig({
    this.productId,
    this.productName,
    this.productCode,
    required this.fields,
  });

  factory WebBatchProductConfig.fromJson(Map<String, dynamic> json) {
    final rawFields =
        json['fields'] ??
        json['values'] ??
        json['field_values'] ??
        json['details'] ??
        json['attributes'];

    return WebBatchProductConfig(
      productId: json['product_id']?.toString(),
      productName:
          json['product_name']?.toString() ??
          json['product']?.toString() ??
          json['name']?.toString(),
      productCode: json['product_code']?.toString() ?? json['code']?.toString(),
      fields: _fieldsFrom(rawFields),
    );
  }

  final String? productId;
  final String? productName;
  final String? productCode;
  final Map<String, dynamic> fields;

  static List<WebBatchProductConfig> fromCollection(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (item) => WebBatchProductConfig.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList();
    }
    if (raw is Map) {
      return raw.entries.where((entry) => entry.value is Map).map((entry) {
        final item = (entry.value as Map).map(
          (key, value) => MapEntry('$key', value),
        );
        item.putIfAbsent('product_name', () => entry.key.toString());
        return WebBatchProductConfig.fromJson(item);
      }).toList();
    }
    return const [];
  }

  static Map<String, dynamic> _fieldsFrom(Object? raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    if (raw is List) {
      final result = <String, dynamic>{};
      for (final item in raw.whereType<Map>()) {
        final key =
            item['field'] ?? item['label'] ?? item['name'] ?? item['key'];
        final value =
            item['value'] ?? item['display_value'] ?? item['raw_value'];
        final textKey = key?.toString().trim();
        if (textKey != null && textKey.isNotEmpty && value != null) {
          result[textKey] = value;
        }
      }
      return result;
    }
    return const {};
  }
}

class _WeighingDashboardScreenState extends State<WeighingDashboardScreen> {
  late final LocalDatabase database;
  late final ProductRepository productRepository;
  late ProductionRepository productionRepository;
  late final InventoryRepository inventoryRepository;
  late final LabelTemplateRepository labelRepository;
  late final BluetoothThermalPrinterAdapter printerAdapter;
  late final AndroidBluetoothSettings bluetoothSettings;
  late SyncQueueService syncQueueService;
  late ScaleAdapter scale;
  late final ScaleConnectionManager scaleManager;
  late final WeighingController controller;
  late final WeighingSession session;
  StreamSubscription<ScaleReading>? subscription;
  StreamSubscription<ScaleConnectionStatus>? statusSubscription;

  List<ProductConfig> products = [];
  List<DynamicFieldConfig> fields = [];
  List<WebBatchConfig> webBatches = [];
  List<String> batchOptions = [];
  ProductConfig? selectedProduct;
  ProductVariantConfig? selectedVariant;
  String? selectedBatch;
  bool batchEntryMode = false;
  ScaleReading reading = ScaleReading(
    grossWeight: 0,
    unit: 'kg',
    isStable: true,
    raw: 'SIM',
    recordedAt: DateTime.now(),
  );
  WeightComputation? computation;
  LabelTemplateConfig? labelTemplate;
  LocalInwardSession? activeInwardSession;
  List<LocalProductionTransaction> recentProductions = [];
  int pendingSync = 0;
  double currentInventory = 0;
  String? lastSavedSerial;
  String? lastSavedBarcode;
  bool autoCapture = false;
  double? manualTare;
  ScaleConnectionStatus scaleStatus = ScaleConnectionStatus.disconnected;
  PrinterConnectionStatus printerStatus = PrinterConnectionStatus.disconnected;
  ScaleDevice? configuredScale;
  PrinterDevice? configuredPrinter;
  String printerMessage = 'Printer not connected';
  String scaleMessage = 'Scale not connected';
  bool usingSimulator = false;
  bool refreshing = false;
  bool savingAndPrinting = false;
  bool qrDiagnosticBusy = false;
  String appVersionLabel = 'Version loading…';
  final Map<String, TextEditingController> fieldControllers = {};
  final Map<String, String> dynamicValues = {};
  final Set<String> _batchAppliedKeys = {};
  final TextEditingController manualTareController = TextEditingController();
  static const _deletePasswordKey = 'weighing.delete_password';

  static const scaleProfiles = [
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

  bool get _scaleConnected =>
      scaleStatus == ScaleConnectionStatus.receiving ||
      scaleStatus == ScaleConnectionStatus.connected;

  String get _autoCaptureStatus {
    if (!autoCapture) {
      return 'Automatically save and print when weight is stable and within range.';
    }
    if (!_scaleConnected) {
      return 'Waiting for the weighing scale to connect.';
    }

    final computed = computation;
    if (computed == null || computed.gross <= session.resetThreshold) {
      return 'Ready. Place an item on the scale.';
    }
    if (!WeighingController.isWithinAllowedRange(computed)) {
      return 'Waiting: net weight is outside the product range.';
    }

    return switch (session.state) {
      CaptureState.weightDetected || CaptureState.stabilising =>
        reading.stabilitySignalPresent
            ? 'Waiting for the scale to report a stable weight.'
            : 'Checking numerical stability… keep the item still.',
      CaptureState.stable ||
      CaptureState.readyToCapture => 'Weight ready. Saving and printing.',
      CaptureState.saving => 'Saving the weighment.',
      CaptureState.saved || CaptureState.waitingForItemRemoval =>
        'Printed. Remove the item until the scale returns to zero.',
      CaptureState.validated =>
        'Waiting: net weight is outside the product range.',
      CaptureState.idle => 'Ready. Place an item on the scale.',
    };
  }

  Widget _autoCaptureControl() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: autoCapture,
      onChanged: (value) => setState(() => autoCapture = value),
      title: const Text(
        'Auto capture',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _autoCaptureStatus,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _weightRangeBadge(
    WeightComputation? computed, {
    bool compact = false,
  }) {
    final status = computed?.rangeStatus ?? WeightRangeStatus.noRule;
    final (background, foreground, icon) = switch (status) {
      WeightRangeStatus.underweight => (
        const Color(0xFFFFF1F2),
        const Color(0xFFBE123C),
        Icons.arrow_downward_rounded,
      ),
      WeightRangeStatus.accepted => (
        const Color(0xFFECFDF3),
        const Color(0xFF067647),
        Icons.check_circle_rounded,
      ),
      WeightRangeStatus.overweight => (
        const Color(0xFFFFF1F2),
        const Color(0xFFB42318),
        Icons.arrow_upward_rounded,
      ),
      WeightRangeStatus.noRule => (
        const Color(0xFFF1F5F9),
        const Color(0xFF475569),
        Icons.horizontal_rule_rounded,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: foreground.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: foreground),
          const SizedBox(width: 5),
          Text(
            WeighingController.rangeStatusLabel(status),
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    database = LocalDatabase();
    productRepository = ProductRepository(database: database);
    productionRepository = ProductionRepository(database: database);
    inventoryRepository = InventoryRepository(database);
    labelRepository = LabelTemplateRepository(database: database);
    printerAdapter = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.printerAdapter
        : BluetoothThermalPrinterAdapter();
    bluetoothSettings = const AndroidBluetoothSettings();
    syncQueueService = SyncQueueService(database);
    scaleManager = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.scaleManager
        : ScaleConnectionManager(
            transport: ClassicSppTransport(),
            profile: scaleProfiles.first,
          );
    scale = SimulatedScaleAdapter();
    controller = WeighingController(
      ruleResolver: WeightRuleResolver(),
      conversionCalculator: const UnitConversionCalculator(),
    );
    session = WeighingSession();
    _loadAppVersion();
    _load();
    _connectScale();
    _loadPrinter();
  }

  Future<void> _loadAppVersion() async {
    try {
      final package = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        appVersionLabel = 'v${package.version} (build ${package.buildNumber})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => appVersionLabel = 'v1.1.17 (build 22)');
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    statusSubscription?.cancel();
    for (final controller in fieldControllers.values) {
      controller.dispose();
    }
    manualTareController.dispose();
    if (!AppEdition.webManagedLabels) {
      scale.disconnect();
    }
    super.dispose();
  }

  Future<void> _connectScale() async {
    await subscription?.cancel();
    await statusSubscription?.cancel();
    if (!AppEdition.webManagedLabels) {
      await scale.disconnect();
    }

    final savedDevice = await scaleManager.savedDevice();
    final savedProfile = await scaleManager.savedProfile();
    configuredScale = savedDevice;

    if (savedDevice == null) {
      final simulated = SimulatedScaleAdapter();
      scale = simulated;
      usingSimulator = true;
      await simulated.connect();
      scaleStatus = simulated.status;
      scaleMessage = 'Demo scale active. Tap Connect Scale for real hardware.';
      subscription = simulated.readings.listen(_onReading);
      if (mounted) setState(() {});
      return;
    }

    try {
      final BluetoothScaleAdapter bluetooth;
      if (AppEdition.webManagedLabels) {
        final deviceSession = AppDeviceSession.instance;
        subscription = deviceSession.readings.listen(_onReading);
        statusSubscription = deviceSession.scaleStatuses.listen((status) {
          if (mounted) setState(() => scaleStatus = status);
        });
        bluetooth =
            await deviceSession.connectSavedScale() ??
            await deviceSession.connectScale(
              device: savedDevice,
              profile: savedProfile,
              autoReconnect: true,
              saveSelection: false,
            );
      } else {
        bluetooth = BluetoothScaleAdapter(
          transport: ClassicSppTransport(),
          profile: savedProfile,
          deviceId: savedDevice.id,
        );
        subscription = bluetooth.readings.listen(_onReading);
        statusSubscription = bluetooth.statusStream.listen((status) {
          if (mounted) setState(() => scaleStatus = status);
        });
        await bluetooth.connect();
      }
      scale = bluetooth;
      usingSimulator = false;
      if (mounted) {
        setState(() {
          scaleStatus = bluetooth.status;
          scaleMessage = 'Connected to ${savedDevice.name}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          scaleStatus = ScaleConnectionStatus.error;
          scaleMessage = 'Scale connection failed: $error';
        });
      }
    }
  }

  Future<void> _refreshMainScreen() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      if (AppEdition.webManagedLabels) {
        await AppDeviceSession.instance.refreshConnections();
      } else {
        await _connectScale();
        await _loadPrinter();
      }
      await _load();
      await _loadPrinter();
      if (mounted) {
        _showCornerMessage('Products, label and device connections refreshed.');
      }
    } catch (error) {
      if (mounted) {
        _showCornerMessage('Refresh failed: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> _load() async {
    final client = await ApiSession.client();
    syncQueueService = SyncQueueService(database, apiClient: client);
    productionRepository = ProductionRepository(
      database: database,
      apiClient: client,
    );
    if (client != null) {
      final deviceId = await ApiSession.deviceId();
      await ProductRepository(
        database: database,
        apiClient: client,
      ).sync(deviceId: deviceId);
      await LabelTemplateRepository(
        database: database,
        apiClient: client,
      ).sync();
      await syncQueueService.retryPending(passes: 4);
    }
    final loadedProducts = await productRepository.cachedProducts();
    final loadedFields = await _weighingFields();
    final loadedBatches = (await productRepository.cachedBatches())
        .map(WebBatchConfig.fromJson)
        .where((batch) => batch.name.isNotEmpty)
        .toList();
    final loadedBatchOptions =
        loadedBatches.map((batch) => batch.name).toSet().toList()
          ..sort((a, b) => a.compareTo(b));
    final pending = await syncQueueService.pendingCount();
    if (!mounted) return;
    setState(() {
      products = loadedProducts;
      fields = loadedFields;
      webBatches = loadedBatches;
      batchOptions = loadedBatchOptions;
      pendingSync = pending;
      if (selectedBatch != null &&
          !loadedBatchOptions.contains(selectedBatch)) {
        selectedBatch = null;
      }
      selectedProduct = batchEntryMode
          ? _preferredProductForBatch(loadedProducts, selectedBatch)
          : loadedProducts
                    .where((product) => product.id == selectedProduct?.id)
                    .firstOrNull ??
                loadedProducts.firstOrNull;
      selectedVariant = null;
    });
    _applyBatchDetails();
    await _refreshDerived();
  }

  Future<List<DynamicFieldConfig>> _weighingFields() async {
    final productFields = await productRepository.cachedFields(
      entityType: 'product',
    );
    final variantFields = await productRepository.cachedFields(
      entityType: 'product_variant',
    );
    final byKey = <String, DynamicFieldConfig>{};
    for (final field in [...productFields, ...variantFields]) {
      byKey.putIfAbsent(field.internalKey, () => field);
    }
    return byKey.values.toList()
      ..sort((a, b) => a.fieldLabel.compareTo(b.fieldLabel));
  }

  List<ProductConfig> get _visibleProducts {
    if (!batchEntryMode) return products;
    final batch = selectedBatch?.trim();
    if (batch == null || batch.isEmpty) return const [];
    final config = _webBatchFor(batch);
    if (config == null) return const [];

    return products
        .where(
          (product) => config.products.any(
            (batchProduct) => _matchesBatchProduct(product, batchProduct),
          ),
        )
        .toList();
  }

  WebBatchConfig? _webBatchFor(String batchName) {
    final wanted = _normalizedKey(batchName);
    return webBatches
        .where((batch) => _normalizedKey(batch.name) == wanted)
        .firstOrNull;
  }

  WebBatchProductConfig? _webBatchProductFor(ProductConfig product) {
    final batch = selectedBatch?.trim();
    if (batch == null || batch.isEmpty) return null;
    final config = _webBatchFor(batch);
    return config?.products
        .where((item) => _matchesBatchProduct(product, item))
        .firstOrNull;
  }

  bool _matchesBatchProduct(
    ProductConfig product,
    WebBatchProductConfig batchProduct,
  ) {
    final productId = batchProduct.productId?.trim();
    if (productId != null && productId.isNotEmpty && product.id == productId) {
      return true;
    }
    final productName = batchProduct.productName?.trim();
    if (productName != null &&
        productName.isNotEmpty &&
        _normalizedKey(product.name) == _normalizedKey(productName)) {
      return true;
    }
    final productCode = batchProduct.productCode?.trim();
    return productCode != null &&
        productCode.isNotEmpty &&
        _normalizedKey(product.productCode) == _normalizedKey(productCode);
  }

  ProductConfig? _preferredProductForBatch(
    List<ProductConfig> source,
    String? batchName,
  ) {
    if (batchName == null || batchName.trim().isEmpty) return null;
    final config = _webBatchFor(batchName);
    if (config == null) return null;
    return source
        .where(
          (product) => config.products.any(
            (batchProduct) => _matchesBatchProduct(product, batchProduct),
          ),
        )
        .firstOrNull;
  }

  void _applyBatchDetails() {
    for (final key in _batchAppliedKeys) {
      dynamicValues.remove(key);
      fieldControllers[key]?.clear();
    }
    _batchAppliedKeys.clear();

    if (!batchEntryMode) return;
    final product = selectedProduct;
    final batch = selectedBatch?.trim();
    if (product == null || batch == null || batch.isEmpty) return;

    _setBatchValue('batch', batch);
    _setBatchValue('batch_number', batch);
    for (final field in fields.where(_isBatchField)) {
      _setBatchValue(field.internalKey, batch);
    }

    final batchProduct = _webBatchProductFor(product);
    if (batchProduct == null) return;
    for (final entry in batchProduct.fields.entries) {
      final field = fields
          .where(
            (candidate) =>
                _normalizedKey(candidate.internalKey) ==
                    _normalizedKey(entry.key) ||
                _normalizedKey(candidate.fieldLabel) ==
                    _normalizedKey(entry.key),
          )
          .firstOrNull;
      _setBatchValue(field?.internalKey ?? entry.key, entry.value);
    }
  }

  void _setBatchValue(String key, Object? rawValue) {
    final value = _displayValue(rawValue);
    if (value == null || value.isEmpty) return;
    dynamicValues[key] = value;
    fieldControllers[key]?.text = value;
    _batchAppliedKeys.add(key);
  }

  String? _displayValue(Object? rawValue) {
    if (rawValue == null) return null;
    if (rawValue is Map) {
      return _displayValue(
        rawValue['label'] ??
            rawValue['display_value'] ??
            rawValue['value'] ??
            rawValue['raw_value'] ??
            rawValue['internal_value'] ??
            rawValue['name'],
      );
    }
    final value = rawValue.toString().trim();
    return value.isEmpty ? null : value;
  }

  bool _isBatchField(DynamicFieldConfig field) {
    return _normalizedKey(field.internalKey).contains('batch') ||
        _normalizedKey(field.fieldLabel).contains('batch');
  }

  String _normalizedKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  String _batchPrintValue() =>
      batchEntryMode ? selectedBatch?.trim() ?? '' : '';

  Future<void> _loadPrinter() async {
    final saved = await printerAdapter.savedPrinter();
    final connected = await printerAdapter.isConnected();
    if (!mounted) return;
    setState(() {
      configuredPrinter = saved;
      printerStatus = connected
          ? PrinterConnectionStatus.connected
          : PrinterConnectionStatus.disconnected;
      printerMessage = saved == null
          ? 'Configure printer first'
          : connected
          ? 'Connected to ${saved.name}'
          : 'Saved printer: ${saved.name}';
    });
    if (saved != null && !connected) {
      unawaited(_autoConnectPrinter(saved));
    }
  }

  Future<void> _autoConnectPrinter(PrinterDevice saved) async {
    try {
      await printerAdapter.connect(saved.id);
      if (!mounted) return;
      setState(() {
        configuredPrinter = saved;
        printerStatus = PrinterConnectionStatus.connected;
        printerMessage = 'Connected to ${saved.name}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        printerStatus = PrinterConnectionStatus.disconnected;
        printerMessage =
            'Saved printer: ${saved.name}. Tap printer icon to reconnect.';
      });
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    if (connect.isPermanentlyDenied || scan.isPermanentlyDenied) {
      await openAppSettings();
    }
    return connect.isGranted && scan.isGranted;
  }

  Future<void> _showScaleConnector() async {
    final granted = await _requestBluetoothPermissions();
    if (!granted && mounted) {
      setState(() => scaleMessage = 'Bluetooth permission required.');
      return;
    }

    final transport = ClassicSppTransport();
    var devices = <ScaleDevice>[];
    var selectedDevice = configuredScale ?? await scaleManager.savedDevice();
    var selectedProfile = await scaleManager.savedProfile();
    var busy = false;
    var loaded = false;
    var message = scaleMessage;

    Future<void> refresh(StateSetter sheetSetState) async {
      sheetSetState(() {
        busy = true;
        loaded = true;
        message = 'Loading paired Bluetooth scales...';
      });
      try {
        final list = await transport.pairedDevices();
        sheetSetState(() {
          devices = list;
          if (selectedDevice != null && !devices.contains(selectedDevice)) {
            selectedDevice = null;
          }
          message = list.isEmpty
              ? 'No paired scales found. Pair the scale in Android Bluetooth settings first.'
              : 'Select your scale and tap Connect.';
        });
      } catch (error) {
        sheetSetState(() => message = 'Could not list scales: $error');
      } finally {
        sheetSetState(() => busy = false);
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, sheetSetState) {
          if (!loaded && !busy) {
            Future.microtask(() => refresh(sheetSetState));
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              6,
              18,
              18 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Connect Weighing Scale',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(color: Color(0xFF536685)),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<ScaleDevice>(
                    initialValue: devices.contains(selectedDevice)
                        ? selectedDevice
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Paired Classic Bluetooth scale',
                      border: OutlineInputBorder(),
                    ),
                    items: devices
                        .map(
                          (device) => DropdownMenuItem(
                            value: device,
                            child: Text(
                              '${device.name}  ${device.address ?? device.id}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (device) =>
                        sheetSetState(() => selectedDevice = device),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ScaleParsingProfile>(
                    initialValue: scaleProfiles.contains(selectedProfile)
                        ? selectedProfile
                        : scaleProfiles.first,
                    decoration: const InputDecoration(
                      labelText: 'Parsing profile',
                      border: OutlineInputBorder(),
                    ),
                    items: scaleProfiles
                        .map(
                          (profile) => DropdownMenuItem(
                            value: profile,
                            child: Text(profile.name),
                          ),
                        )
                        .toList(),
                    onChanged: (profile) => sheetSetState(
                      () => selectedProfile = profile ?? scaleProfiles.first,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => bluetoothSettings.open(),
                          icon: const Icon(Icons.bluetooth_searching_rounded),
                          label: const Text('Pair Device'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () => refresh(sheetSetState),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy || selectedDevice == null
                              ? null
                              : () async {
                                  final device = selectedDevice!;
                                  sheetSetState(() {
                                    busy = true;
                                    message = 'Connecting to ${device.name}...';
                                  });
                                  await scaleManager.save(
                                    device: device,
                                    profile: selectedProfile,
                                    autoReconnect: true,
                                  );
                                  setState(() {
                                    configuredScale = device;
                                    scaleMessage =
                                        'Connecting to ${device.name}...';
                                  });
                                  await _connectScale();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          icon: const Icon(Icons.sensors_rounded),
                          label: const Text('Connect'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.go('/settings'),
                    child: const Text('Open full diagnostics'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    await transport.disconnect();
  }

  Future<void> _showPrinterConnector() async {
    final granted = await _requestBluetoothPermissions();
    if (!granted && mounted) {
      setState(() => printerMessage = 'Bluetooth permission required.');
      return;
    }

    var printers = <PrinterDevice>[];
    var selectedPrinter =
        configuredPrinter ?? await printerAdapter.savedPrinter();
    var busy = false;
    var loaded = false;
    var message = printerMessage;

    Future<void> refresh(StateSetter sheetSetState) async {
      sheetSetState(() {
        busy = true;
        loaded = true;
        message =
            'Scanning BLE printers and listing TVS Native paired printers...';
      });
      try {
        final list = await printerAdapter.discover();
        sheetSetState(() {
          printers = list;
          if (selectedPrinter != null && !printers.contains(selectedPrinter)) {
            selectedPrinter = null;
          }
          message = list.isEmpty
              ? 'No printers found. For TVS Native, pair the printer in Android Bluetooth settings first.'
              : 'Select BLE TSPL or TVS Native, then tap Connect.';
        });
      } catch (error) {
        sheetSetState(() => message = 'Could not list printers: $error');
      } finally {
        sheetSetState(() => busy = false);
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, sheetSetState) {
          if (!loaded && !busy) {
            Future.microtask(() => refresh(sheetSetState));
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              6,
              18,
              18 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Connect Label Printer',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(color: Color(0xFF536685)),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<PrinterDevice>(
                      initialValue: printers.contains(selectedPrinter)
                          ? selectedPrinter
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Printer connection',
                        border: OutlineInputBorder(),
                      ),
                      items: printers
                          .map(
                            (printer) => DropdownMenuItem(
                              value: printer,
                              child: Text(
                                '${printer.name}  ${printer.address ?? printer.id}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (printer) =>
                          sheetSetState(() => selectedPrinter = printer),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => bluetoothSettings.open(),
                            icon: const Icon(Icons.bluetooth_searching_rounded),
                            label: const Text('Bluetooth Settings'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => refresh(sheetSetState),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: busy || selectedPrinter == null
                                ? null
                                : () async {
                                    final printer = selectedPrinter!;
                                    sheetSetState(() {
                                      busy = true;
                                      message =
                                          'Connecting to ${printer.name}...';
                                    });
                                    try {
                                      await printerAdapter.connect(printer.id);
                                      await printerAdapter.savePrinter(printer);
                                      if (!mounted) return;
                                      setState(() {
                                        configuredPrinter = printer;
                                        printerStatus =
                                            PrinterConnectionStatus.connected;
                                        printerMessage =
                                            'Connected to ${printer.name}';
                                      });
                                      sheetSetState(() {
                                        busy = false;
                                        selectedPrinter = printer;
                                        message =
                                            'Connected to ${printer.name}. Tap Test Print below to check text, barcode and QR.';
                                      });
                                    } catch (error) {
                                      sheetSetState(() {
                                        busy = false;
                                        message = 'Connection failed: $error';
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed:
                          printerStatus == PrinterConnectionStatus.connected
                          ? () async {
                              sheetSetState(() {
                                busy = true;
                                message =
                                    'Sending text, barcode and QR test print...';
                              });
                              // Use the exact raw TSPL command proven on the
                              // TVS LP 46 Dlite+ BT in QR Diagnostic Test B.
                              final result = await printerAdapter
                                  .printQrDiagnostic(
                                    QrDiagnosticMode.tsplCommand,
                                  );
                              sheetSetState(() {
                                busy = false;
                                message = result.message ?? result.status;
                              });
                              if (mounted) {
                                setState(() {
                                  printerStatus = result.status == 'failed'
                                      ? PrinterConnectionStatus.error
                                      : PrinterConnectionStatus.connected;
                                  printerMessage =
                                      result.message ?? result.status;
                                });
                              }
                            }
                          : null,
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Test Print (Text + Barcode + QR)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshDerived() async {
    labelTemplate = await labelRepository.effective(
      productId: selectedProduct?.id,
      variantId: null,
      preferServerTemplates: true,
    );
    currentInventory = selectedProduct == null
        ? 0
        : await inventoryRepository.productWeight(
            selectedProduct!.id,
            variantId: null,
          );
    pendingSync = await syncQueueService.pendingCount();
    activeInwardSession = await productionRepository.openSession();
    final session = activeInwardSession;
    recentProductions = session?.status == 'open'
        ? await productionRepository.bySession(session!.id)
        : <LocalProductionTransaction>[];
    if (mounted) setState(() {});
  }

  Future<void> _onReading(ScaleReading value) async {
    if (!mounted) return;
    final computed = controller.compute(
      reading: value,
      product: selectedProduct,
      variant: null,
      manualTare: manualTare,
    );
    final ready = session.update(value, computed);
    setState(() {
      reading = value;
      computation = computed;
    });
    if (WeighingController.shouldAutoSaveAndPrint(
      autoCaptureEnabled: autoCapture,
      readingReady: ready,
    )) {
      await _saveAndPrint();
    }
  }

  Future<LocalProductionTransaction?> _capture({
    bool syncAfterSave = true,
  }) async {
    if (batchEntryMode && (selectedBatch == null || selectedBatch!.isEmpty)) {
      _showCornerMessage('Print stopped: select a batch first.', error: true);
      return null;
    }
    final product = selectedProduct;
    final computed = computation;
    if (product == null) {
      _showCornerMessage('Print stopped: select a product first.', error: true);
      return null;
    }
    _applyBatchDetails();
    if (computed == null) {
      _showCornerMessage(
        'Print stopped: waiting for a live scale reading. Confirm the scale is connected.',
        error: true,
      );
      return null;
    }
    if (reading.grossWeight < 0 || computed.gross <= 0 || computed.net <= 0) {
      _showCornerMessage(
        'Negative or zero weight cannot be saved. Remove item, zero scale, then weigh again.',
        error: true,
      );
      return null;
    }
    if (!WeighingController.isWithinAllowedRange(computed)) {
      _showCornerMessage(
        'Print stopped: the net weight is outside this product’s configured minimum and maximum range.',
        error: true,
      );
      return null;
    }
    var inwardSession = activeInwardSession;
    if (inwardSession?.status != 'open') {
      inwardSession = await productionRepository.startSession();
      if (!mounted) return null;
      setState(() => activeInwardSession = inwardSession);
    }
    final id = await productionRepository.capture(
      product: product,
      variant: null,
      computation: computed,
      reading: reading,
      dynamicValues: Map<String, dynamic>.from(dynamicValues),
      inwardSession: inwardSession,
    );
    session.markCaptured(computed.net);
    final recent = await productionRepository.recent(limit: 1);
    final saved = recent.firstOrNull;
    setState(() {
      lastSavedSerial = saved?.serialNumber ?? id;
      lastSavedBarcode = saved?.barcodeValue ?? lastSavedSerial;
    });
    await _refreshDerived();
    if (syncAfterSave) unawaited(_syncAfterCapture());
    return saved;
  }

  Future<void> _syncAfterCapture() async {
    await syncQueueService.retryPending(passes: 1);
    if (!mounted) return;
    final pending = await syncQueueService.pendingCount();
    if (mounted) setState(() => pendingSync = pending);
  }

  Future<void> _saveAndPrint() async {
    if (savingAndPrinting) return;
    setState(() => savingAndPrinting = true);
    try {
      if (!await _validateDividedWeightTemplate()) return;
      final saved = await _capture(syncAfterSave: false);
      if (saved == null) return;
      await _printLabel(saved);
      unawaited(_syncAfterCapture());
    } finally {
      if (mounted) setState(() => savingAndPrinting = false);
    }
  }

  Future<bool> _validateDividedWeightTemplate() async {
    final product = selectedProduct;
    if (product == null) return true;
    try {
      await labelRepository.sync();
    } catch (_) {
      // Offline printing may continue with the last successfully synced template.
    }
    final activeTemplate = await labelRepository.effective(
      productId: product.id,
      variantId: null,
      preferServerTemplates: true,
    );
    final elements = activeTemplate?.templateJson['elements'];
    if (elements is! List) return true;

    for (final element in elements.whereType<Map>()) {
      final key = element['bindingKey']?.toString() ?? '';
      if (!key.startsWith('weight.gross_per_piece.') &&
          !key.startsWith('weight.net_per_piece.')) {
        continue;
      }
      final internalKey = key.split('.').last;
      final raw = dynamicValues[internalKey]?.trim() ?? '';
      final divisor = num.tryParse(raw);
      if (divisor == null || divisor <= 0) {
        final field = fields
            .where((candidate) => candidate.internalKey == internalKey)
            .firstOrNull;
        _showCornerMessage(
          'Print stopped: select a valid ${field?.fieldLabel ?? internalKey} quantity for divided weight.',
          error: true,
        );
        return false;
      }
    }
    labelTemplate = activeTemplate;
    return true;
  }

  Future<void> _showQrDiagnosticPicker() async {
    if (!AppEdition.qrDiagnostic || qrDiagnosticBusy) return;
    final mode = await showDialog<QrDiagnosticMode>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.qr_code_2_rounded,
          color: Color(0xFFF97316),
          size: 38,
        ),
        title: const Text('Temporary QR Printer Test'),
        content: const Text(
          'Choose one QR method. This prints a diagnostic label only—it does not save a weighment, change inventory, or sync a transaction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ...QrDiagnosticMode.values.map(
            (mode) => FilledButton(
              onPressed: () => Navigator.of(context).pop(mode),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
              ),
              child: Text('TEST ${mode.marker} · ${mode.label}'),
            ),
          ),
        ],
      ),
    );
    if (mode != null && mounted) {
      await _runQrDiagnostic(mode);
    }
  }

  Future<void> _runQrDiagnostic(QrDiagnosticMode mode) async {
    if (qrDiagnosticBusy) return;
    final printer = configuredPrinter ?? await printerAdapter.savedPrinter();
    if (printer == null) {
      _showCornerMessage(
        'Connect the TVS printer before running the QR diagnostic.',
        error: true,
      );
      return;
    }

    setState(() {
      qrDiagnosticBusy = true;
      configuredPrinter = printer;
      printerStatus = PrinterConnectionStatus.connecting;
      printerMessage = 'Preparing QR Test ${mode.marker}...';
    });
    try {
      if (!await printerAdapter.isConnected()) {
        await printerAdapter.connect(printer.id);
      }
      if (!mounted) return;
      setState(() {
        printerStatus = PrinterConnectionStatus.printing;
        printerMessage = 'Printing QR Test ${mode.marker}...';
      });
      final result = await printerAdapter.printQrDiagnostic(mode);
      if (!mounted) return;
      final connected = await _printerStillConnected();
      setState(() {
        printerStatus = connected
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.disconnected;
        printerMessage = result.message ?? result.status;
      });
      _showCornerMessage(
        result.message ?? result.status,
        error: result.status == 'failed',
      );
    } catch (error) {
      if (!mounted) return;
      final connected = await _printerStillConnected();
      setState(() {
        printerStatus = connected
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.disconnected;
        printerMessage = 'QR Test ${mode.marker} failed: $error';
      });
      _showCornerMessage(printerMessage, error: true);
    } finally {
      if (mounted) setState(() => qrDiagnosticBusy = false);
    }
  }

  Widget _qrDiagnosticButton() {
    return OutlinedButton.icon(
      onPressed: qrDiagnosticBusy ? null : _showQrDiagnosticPicker,
      icon: qrDiagnosticBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.qr_code_2_rounded),
      label: const Text('QR PRINTER TEST — TEMPORARY'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        foregroundColor: const Color(0xFF9A3412),
        backgroundColor: const Color(0xFFFFEDD5),
        side: const BorderSide(color: Color(0xFFF97316), width: 3),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }

  Future<void> _printLabel(LocalProductionTransaction saved) async {
    final product = selectedProduct;
    final computed = computation;
    if (product == null || computed == null) return;
    if (reading.grossWeight < 0 || computed.gross <= 0 || computed.net <= 0) {
      setState(() {
        printerStatus = PrinterConnectionStatus.connected;
        printerMessage = 'Print blocked: invalid negative or zero weight.';
      });
      _showCornerMessage(
        'Print blocked: invalid negative or zero weight.',
        error: true,
      );
      return;
    }

    final printer = configuredPrinter ?? await printerAdapter.savedPrinter();
    if (printer == null) {
      if (!mounted) return;
      setState(() {
        printerStatus = PrinterConnectionStatus.error;
        printerMessage = 'Open Printer Settings and connect a printer first.';
      });
      return;
    }

    try {
      setState(() {
        configuredPrinter = printer;
        printerStatus = PrinterConnectionStatus.connecting;
        printerMessage = 'Connecting to ${printer.name}...';
      });
      if (!await printerAdapter.isConnected()) {
        await printerAdapter.connect(printer.id);
      }
      setState(() {
        printerStatus = PrinterConnectionStatus.printing;
        printerMessage = 'Sending label...';
      });
      try {
        await labelRepository.sync();
      } catch (_) {
        // Continue with the last cached web template if internet is temporarily unavailable.
      }
      final activeTemplate = await labelRepository.effective(
        productId: product.id,
        variantId: null,
        preferServerTemplates: true,
      );
      labelTemplate = activeTemplate;
      if (AppEdition.webManagedLabels && activeTemplate == null) {
        if (!mounted) return;
        setState(() {
          printerStatus = PrinterConnectionStatus.error;
          printerMessage =
              'No web label is marked default. Set a default template in the web panel and sync again.';
        });
        _showCornerMessage(printerMessage, error: true);
        return;
      }
      String? qrValue;
      if (AppEdition.webManagedLabels && _templateHasQr(activeTemplate)) {
        Object? qrError;
        for (var attempt = 1; attempt <= 3 && qrValue == null; attempt++) {
          try {
            qrValue = await const QrVerificationRepository().createPublicUrl(
              sourceTransactionId: saved.id,
              productId: product.id,
              variantId: saved.variantId,
              productName: product.name,
              variantName: selectedVariant?.name,
              variantCode: selectedVariant?.variantCode,
              serialNumber: saved.serialNumber,
              barcodeValue: saved.barcodeValue,
              grossWeight: saved.grossWeight,
              tareWeight: saved.tareWeight,
              netWeight: saved.netWeight,
              pieceQuantity: saved.pieceQuantity,
              unit: saved.unit,
              printedAt: saved.capturedAt,
              dynamicValues: Map<String, dynamic>.from(dynamicValues),
              productRaw: Map<String, dynamic>.from(product.raw),
            );
          } catch (error) {
            qrError = error;
            if (attempt == 1) {
              await syncQueueService.retryPending(passes: 1);
            }
            if (attempt < 3) {
              await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
            }
          }
        }
        if (qrValue == null) {
          if (!mounted) return;
          setState(() {
            printerStatus = PrinterConnectionStatus.connected;
            printerMessage =
                'QR verification failed after 3 attempts: $qrError. Label was not printed to prevent an invalid QR.';
          });
          _showCornerMessage(printerMessage, error: true);
          return;
        }
      }
      final adminCompanyName = await ApiSession.companyName();
      final result = await printerAdapter.print(
        PrintJob(
          jobId: 'print_${DateTime.now().microsecondsSinceEpoch}',
          template: activeTemplate?.templateJson ?? const {},
          data: {
            'company_name':
                adminCompanyName ?? _companyNameForTemplate(activeTemplate),
            'product_name': product.name,
            'variant_name': null,
            'batch_number': _batchPrintValue(),
            'serial_number': saved.serialNumber,
            'barcode_value': saved.barcodeValue,
            'customer_barcode_enabled':
                product.raw['customer_barcode_enabled'] ?? false,
            'customer_barcode_type':
                product.raw['customer_barcode_type'] ?? 'code128',
            'customer_barcode_value': product.raw['customer_barcode_value'],
            'customer_barcode_caption': product.raw['customer_barcode_caption'],
            'qr_value': qrValue,
            'gross_weight': saved.grossWeight,
            'tare_weight': saved.tareWeight,
            'net_weight': saved.netWeight,
            'unit': saved.unit,
            'piece_quantity': saved.pieceQuantity,
            'dynamic_values': Map<String, dynamic>.from(dynamicValues),
            'product_raw': product.raw,
            '_active_template_elements':
                activeTemplate?.templateJson['elements'] ?? const [],
          },
        ),
      );
      if (!mounted) return;
      final stillConnected = await _printerStillConnected();
      setState(() {
        printerStatus = result.status == 'printed'
            ? PrinterConnectionStatus.connected
            : stillConnected
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.disconnected;
        printerMessage = result.message ?? result.status;
      });
      if (result.status == 'printed') {
        _showPrintSuccess();
      } else {
        _showCornerMessage(
          result.message ?? 'Printer rejected the label.',
          error: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      final stillConnected = await _printerStillConnected();
      setState(() {
        printerStatus = stillConnected
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.disconnected;
        printerMessage = 'Print failed: $error';
      });
      _showCornerMessage(printerMessage, error: true);
    }
  }

  bool _templateHasQr(LabelTemplateConfig? template) {
    final elements = template?.templateJson['elements'];
    if (elements is! List) return false;

    return elements.any(
      (element) =>
          element is Map &&
          (element['type']?.toString() == 'qr' ||
              element['type']?.toString() == 'qrcode'),
    );
  }

  Future<bool> _printerStillConnected() async {
    try {
      return await printerAdapter.isConnected();
    } catch (_) {
      return false;
    }
  }

  String _companyNameForTemplate(LabelTemplateConfig? template) {
    final json = template?.templateJson;
    if (json == null) return 'PUNIT ERP';
    final structured = json['structured'];
    if (structured is Map) {
      final company = structured['companyName']?.toString().trim();
      if (company != null && company.isNotEmpty) return company;
    }
    final elements = json['elements'];
    if (elements is List) {
      for (final raw in elements) {
        if (raw is! Map) continue;
        final key = raw['bindingKey']?.toString();
        if (key == 'company.name') {
          final preview = raw['previewValue']?.toString().trim();
          if (preview != null && preview.isNotEmpty) return preview;
          final text = raw['text']?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }
    }
    return 'PUNIT ERP';
  }

  void _showCornerMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        width: 360,
        backgroundColor: error
            ? const Color(0xFFB42318)
            : const Color(0xFF087A4A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _deleteRecentEntry(LocalProductionTransaction row) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    var savedPassword = prefs.getString(_deletePasswordKey);
    final passwordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete weighment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This removes ${row.barcodeValue} from this open transaction.',
            ),
            const SizedBox(height: 12),
            if (savedPassword == null)
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Set delete password',
                  border: OutlineInputBorder(),
                ),
              )
            else
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Delete password',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (savedPassword == null) {
      final newPassword = newPasswordController.text.trim();
      if (newPassword.length < 4) {
        _showCornerMessage('Set at least 4 digits/characters.', error: true);
        return;
      }
      await prefs.setString(_deletePasswordKey, newPassword);
      savedPassword = newPassword;
    } else if (passwordController.text.trim() != savedPassword) {
      _showCornerMessage('Wrong delete password.', error: true);
      return;
    }

    final deleted = await productionRepository.deleteEntry(row);
    if (!deleted) {
      _showCornerMessage(
        'This entry is synced. Login/connection is required to delete it from web.',
        error: true,
      );
      return;
    }
    await _refreshDerived();
    _showCornerMessage('Weighment deleted from current transaction.');
  }

  Future<void> _startInwardSession() async {
    final session = await productionRepository.startSession();
    setState(() => activeInwardSession = session);
    await _refreshDerived();
  }

  Future<void> _finishInwardSession() async {
    final session = activeInwardSession;
    if (session == null) return;
    final saved = await productionRepository.finishSession(session.id);
    setState(() {
      activeInwardSession = saved;
      recentProductions = [];
    });
    final syncResult = await syncQueueService.retryPending(passes: 4);
    await _refreshDerived();
    final rows = await productionRepository.bySession(saved.id);
    final pdf = await _writeInwardPdf(saved, rows);
    if (syncResult.hasFailures && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inward report saved locally. Web sync pending: ${syncResult.message}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
        ),
      );
    }
    if (mounted) _showInwardSavedDialog(saved, pdf);
  }

  Future<void> _editTare() async {
    manualTareController.text = manualTare?.toString() ?? '';
    final value = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tare Weight'),
        content: TextField(
          controller: manualTareController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Tare kg',
            hintText: 'Example: 0.800',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Use Product Tare'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(double.tryParse(manualTareController.text.trim()) ?? 0),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      manualTare = value;
      computation = controller.compute(
        reading: reading,
        product: selectedProduct,
        variant: null,
        manualTare: manualTare,
      );
    });
  }

  void _showPrintSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Print command sent: ${lastSavedBarcode ?? '-'}. Confirm the physical label came out.',
        ),
        behavior: SnackBarBehavior.floating,
        width: 320,
        backgroundColor: const Color(0xFF087A4A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<File> _writeInwardPdf(
    LocalInwardSession session,
    List<LocalProductionTransaction> rows,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, '${session.sessionNumber}.pdf'));
    final lines = <String>[
      'PUNIT ERP - INWARD REPORT',
      'Transaction: ${session.sessionNumber}',
      'Started: ${session.startedAt}',
      'Ended: ${session.endedAt ?? DateTime.now()}',
      'Entries: ${rows.length}',
      'Gross: ${session.totalGrossWeight.toStringAsFixed(3)} kg',
      'Tare: ${session.totalTareWeight.toStringAsFixed(3)} kg',
      'Net: ${session.totalNetWeight.toStringAsFixed(3)} kg',
      '',
      'SR | BARCODE | PRODUCT | GROSS | TARE | NET | TIME',
      ...rows.indexed.map((item) {
        final row = item.$2;
        return '${item.$1 + 1} | ${row.barcodeValue} | ${row.productId} | '
            '${row.grossWeight.toStringAsFixed(3)} | '
            '${row.tareWeight.toStringAsFixed(3)} | '
            '${row.netWeight.toStringAsFixed(3)} | ${row.capturedAt}';
      }),
    ];
    await file.writeAsBytes(_simplePdf(lines));
    return file;
  }

  List<int> _simplePdf(List<String> lines) {
    final escaped = lines
        .take(42)
        .map(
          (line) => line
              .replaceAll(r'\', '/')
              .replaceAll('(', '[')
              .replaceAll(')', ']'),
        )
        .toList();
    final content = StringBuffer();
    var y = 800;
    for (var index = 0; index < escaped.length; index++) {
      final size = index == 0 ? 14 : 8;
      content.writeln('BT /F1 $size Tf 28 $y Td (${escaped[index]}) Tj ET');
      y -= index == 0 ? 24 : 15;
      if (y < 40) break;
    }
    final stream = content.toString();
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
      '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];
    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    var length = buffer.length;
    for (var i = 0; i < objects.length; i++) {
      offsets.add(length);
      final object = '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
      buffer.write(object);
      length += object.length;
    }
    final xref = length;
    buffer.writeln('xref');
    buffer.writeln('0 ${objects.length + 1}');
    buffer.writeln('0000000000 65535 f ');
    for (final offset in offsets.skip(1)) {
      buffer.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    buffer.writeln('trailer << /Root 1 0 R /Size ${objects.length + 1} >>');
    buffer.writeln('startxref');
    buffer.writeln(xref);
    buffer.writeln('%%EOF');
    return latin1.encode(buffer.toString());
  }

  void _showInwardSavedDialog(LocalInwardSession session, File pdf) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Inward saved: ${session.sessionNumber} | PDF: ${pdf.path}',
        ),
        behavior: SnackBarBehavior.floating,
        width: 420,
        backgroundColor: const Color(0xFF0B57D0),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final computed = computation;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FC),
          bottomNavigationBar: compact ? const _MobileBottomNav() : null,
          body: SafeArea(
            child: compact
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: [
                      _mobileTopBar(),
                      _mobileWeightCard(computed),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: computed == null || savingAndPrinting
                            ? null
                            : _saveAndPrint,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('SAVE & PRINT LABEL'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(74),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (AppEdition.qrDiagnostic) ...[
                        const SizedBox(height: 10),
                        _qrDiagnosticButton(),
                      ],
                      const SizedBox(height: 18),
                      _mobileSelectionCard(),
                      const SizedBox(height: 18),
                      _recentCard(compact: true),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _desktopTopBar(),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _desktopWeightPanel(computed),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: SingleChildScrollView(
                                        child: _desktopActionPanel(computed),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Expanded(flex: 4, child: _recentCard()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _desktopTopBar() {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: _stationDecoration(),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to dashboard',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/brand/punit-logo.png',
                width: 104,
                height: 34,
                fit: BoxFit.contain,
              ),
              Text(
                appVersionLabel,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh data and device connections',
            onPressed: refreshing ? null : _refreshMainScreen,
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
          _DeviceBadge(
            label: 'Scale',
            connected: _scaleConnected,
            icon: Icons.sensors_rounded,
          ),
          const SizedBox(width: 8),
          _DeviceBadge(
            label: 'Printer',
            connected: printerStatus == PrinterConnectionStatus.connected,
            icon: Icons.print_outlined,
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 42,
            width: 164,
            child: OutlinedButton.icon(
              onPressed: _showPrinterConnector,
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Printer Config'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 42,
            width: 164,
            child: FilledButton.icon(
              onPressed: _showScaleConnector,
              icon: const Icon(Icons.sensors_rounded, size: 18),
              label: const Text('Connect Scale'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileTopBar() {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/brand/punit-logo.png',
                width: 94,
                height: 32,
                fit: BoxFit.contain,
              ),
              Text(
                appVersionLabel,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh data and connections',
            onPressed: refreshing ? null : _refreshMainScreen,
            icon: refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          _DeviceIcon(
            connected: _scaleConnected,
            icon: Icons.sensors_rounded,
            tooltip: 'Scale connection',
          ),
          _DeviceIcon(
            connected: printerStatus == PrinterConnectionStatus.connected,
            icon: Icons.print_outlined,
            tooltip: 'Printer connection',
          ),
          IconButton(
            onPressed: _showScaleConnector,
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0B57D0)),
          ),
          IconButton(
            onPressed: _showPrinterConnector,
            icon: const Icon(Icons.print_outlined, color: Color(0xFF0B57D0)),
          ),
        ],
      ),
    );
  }

  Widget _desktopWeightPanel(WeightComputation? computed) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _stationDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Weight',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scaleConnected
                          ? 'Connected to weighing scale'
                          : 'Weighing scale not connected',
                      style: TextStyle(
                        color: _scaleConnected
                            ? const Color(0xFF087A4A)
                            : const Color(0xFFB42318),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  _weightRangeBadge(computed),
                  _ScaleLiveBadge(connected: _scaleConnected),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FC),
                border: const Border(
                  top: BorderSide(color: Color(0xFF0B57D0), width: 4),
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    reading.grossWeight.toStringAsFixed(3),
                    style: const TextStyle(
                      color: Color(0xFF0B57D0),
                      fontSize: 200,
                      height: 0.9,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: reading.isStable ? 1 : 0.48,
            minHeight: 4,
            color: const Color(0xFF0B57D0),
            backgroundColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _InlineMeasure(
                label: 'TARE WEIGHT',
                value: '${computed?.tare.toStringAsFixed(3) ?? '0.000'} kg',
                onTap: _editTare,
              ),
              const Spacer(),
              _InlineMeasure(
                label: 'NET WEIGHT',
                value: '${computed?.net.toStringAsFixed(3) ?? '0.000'} kg',
                alignRight: true,
                emphasized: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: computed == null || savingAndPrinting
                ? null
                : _saveAndPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('SAVE & PRINT LABEL'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(62),
            ),
          ),
          if (AppEdition.qrDiagnostic) ...[
            const SizedBox(height: 10),
            _qrDiagnosticButton(),
          ],
        ],
      ),
    );
  }

  Widget _mobileWeightCard(WeightComputation? computed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: _stationDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _ScaleLiveBadge(connected: _scaleConnected, compact: true),
              const Spacer(),
              _weightRangeBadge(computed, compact: true),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'NET WEIGHT',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (computed?.net ?? reading.grossWeight).toStringAsFixed(3),
                  style: const TextStyle(
                    fontSize: 64,
                    height: 0.95,
                    color: Color(0xFF0F1B2D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 7),
                  child: Text(
                    'kg',
                    style: TextStyle(
                      color: Color(0xFF0B57D0),
                      fontWeight: FontWeight.w900,
                      fontSize: 27,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MobileMeasure(
                  label: 'TARE',
                  value: '${computed?.tare.toStringAsFixed(3) ?? '0.000'} kg',
                  onTap: _editTare,
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFD3DDEB)),
              Expanded(
                child: _MobileMeasure(
                  label: 'GROSS',
                  value:
                      '${computed?.gross.toStringAsFixed(3) ?? reading.grossWeight.toStringAsFixed(3)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _desktopActionPanel(WeightComputation? computed) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _stationDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('PRODUCT SELECTION'),
          _entryTypeSelector(),
          if (batchEntryMode) ...[const SizedBox(height: 12), _batchDropdown()],
          const SizedBox(height: 12),
          _productDropdown(),
          _dynamicDetails(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: activeInwardSession?.status == 'open'
                      ? null
                      : _startInwardSession,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('START TRANSACTION'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF087A4A),
                    minimumSize: const Size.fromHeight(76),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  onPressed: activeInwardSession?.status == 'open'
                      ? _finishInwardSession
                      : null,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('STOP TRANSACTION'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B57D0),
                    minimumSize: const Size.fromHeight(76),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SessionStrip(session: activeInwardSession),
          const SizedBox(height: 12),
          _autoCaptureControl(),
        ],
      ),
    );
  }

  Widget _mobileSelectionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('PRODUCT SELECTION'),
        const SizedBox(height: 8),
        _entryTypeSelector(compact: true),
        if (batchEntryMode) ...[
          const SizedBox(height: 10),
          _batchDropdown(compact: true),
        ],
        const SizedBox(height: 10),
        _productDropdown(),
        _dynamicDetails(compact: true),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: activeInwardSession?.status == 'open'
                    ? null
                    : _startInwardSession,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('START TRANSACTION'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: activeInwardSession?.status == 'open'
                    ? _finishInwardSession
                    : null,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('SAVE / STOP'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SessionStrip(session: activeInwardSession),
        const SizedBox(height: 8),
        _autoCaptureControl(),
      ],
    );
  }

  Widget _dynamicDetails({bool compact = false}) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: compact ? 10 : 14),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: const Text(
          'Product detail fields',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'Expand, then tap a dropdown to search and select',
        ),
        children: fields.map((field) => _dynamicField(field)).toList(),
      ),
    );
  }

  Widget _productDropdown() {
    final visibleProducts = _visibleProducts;
    final current = visibleProducts
        .where((product) => product.id == selectedProduct?.id)
        .firstOrNull;

    return SearchableSelectionField<ProductConfig>(
      key: ValueKey(
        'product-${batchEntryMode ? selectedBatch ?? 'none' : 'non-batch'}-${current?.id ?? 'none'}',
      ),
      label: batchEntryMode ? 'Batch product' : 'Product',
      hint: batchEntryMode && selectedBatch == null
          ? 'Select batch first'
          : 'Select product',
      value: current,
      options: visibleProducts,
      optionLabel: (product) => product.name,
      onChanged: (product) async {
        setState(() {
          selectedProduct = product;
          selectedVariant = null;
          _applyBatchDetails();
        });
        await _refreshDerived();
      },
    );
  }

  Widget _entryTypeSelector({bool compact = false}) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: false, label: Text('Non Batch Entry')),
        ButtonSegment(value: true, label: Text('Batch Entry')),
      ],
      selected: {batchEntryMode},
      onSelectionChanged: (selection) async {
        final next = selection.first;
        setState(() {
          batchEntryMode = next;
          selectedBatch = null;
          selectedVariant = null;
          selectedProduct = next ? null : products.firstOrNull;
          _applyBatchDetails();
        });
        await _refreshDerived();
      },
      style: ButtonStyle(visualDensity: compact ? VisualDensity.compact : null),
    );
  }

  Widget _batchDropdown({bool compact = false}) {
    if (batchOptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          border: Border.all(color: const Color(0xFFFDBA74)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No active batches synced. Create a Product Batch in the web panel, then refresh.',
          style: TextStyle(
            color: Color(0xFF9A3412),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('batch-${selectedBatch ?? 'none'}'),
      initialValue: batchOptions.contains(selectedBatch) ? selectedBatch : null,
      isExpanded: true,
      decoration: _fieldDecoration().copyWith(
        labelText: 'Batch',
        hintText: 'Select batch',
      ),
      items: batchOptions
          .map(
            (batch) => DropdownMenuItem(
              value: batch,
              child: Text(batch, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (batch) async {
        setState(() {
          selectedBatch = batch;
          selectedProduct = _preferredProductForBatch(products, batch);
          selectedVariant = null;
          _applyBatchDetails();
        });
        await _refreshDerived();
      },
    );
  }

  Widget _recentCard({bool compact = false}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _stationDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 4 : 18,
              compact ? 4 : 16,
              compact ? 4 : 18,
              compact ? 10 : 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Weighments',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 23 : 16,
                      color: const Color(0xFF0F1B2D),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/reports'),
                  child: const Text('VIEW ALL'),
                ),
              ],
            ),
          ),
          _RecentHeader(compact: compact),
          if (compact)
            SizedBox(height: 238, child: _recentList(compact: true))
          else
            Expanded(child: _recentList()),
        ],
      ),
    );
  }

  Widget _recentList({bool compact = false}) {
    if (recentProductions.isEmpty) {
      return const Center(child: Text('No weighments yet'));
    }

    return ListView.separated(
      primary: false,
      padding: EdgeInsets.zero,
      itemCount: recentProductions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = recentProductions[index];
        return _RecentRow(
          row: row,
          compact: compact,
          onDelete: () => _deleteRecentEntry(row),
        );
      },
    );
  }

  InputDecoration _fieldDecoration() {
    return const InputDecoration(
      filled: true,
      fillColor: Color(0xFFF6F9FE),
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFD6E0EF)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    );
  }

  BoxDecoration _stationDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFDDE6F2)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _dynamicField(DynamicFieldConfig field) {
    if (field.options.isNotEmpty || field.dataType == 'dropdown') {
      final options = field.options
          .map((option) => '${option['label'] ?? option['value']}')
          .where((value) => value.trim().isNotEmpty)
          .toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SearchableSelectionField<String>(
          label: field.required ? '${field.fieldLabel} *' : field.fieldLabel,
          hint: 'Search or select',
          value: _selectedDynamicDropdownValue(field).isEmpty
              ? null
              : _selectedDynamicDropdownValue(field),
          options: options,
          optionLabel: (value) => value,
          enabled: field.editable,
          allowClear: true,
          onChanged: (value) => setState(() {
            if (value == null || value.isEmpty) {
              dynamicValues.remove(field.internalKey);
            } else {
              dynamicValues[field.internalKey] = value;
            }
          }),
        ),
      );
    }

    final controller = fieldControllers.putIfAbsent(
      field.internalKey,
      () => TextEditingController(text: dynamicValues[field.internalKey]),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: field.editable,
        keyboardType: switch (field.dataType) {
          'integer' || 'decimal' => TextInputType.number,
          _ => TextInputType.text,
        },
        onChanged: (value) => dynamicValues[field.internalKey] = value,
        decoration: InputDecoration(
          labelText: field.required
              ? '${field.fieldLabel} *'
              : field.fieldLabel,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String _selectedDynamicDropdownValue(DynamicFieldConfig field) {
    final current = dynamicValues[field.internalKey];
    if (current == null || current.isEmpty) return '';

    for (final option in field.options) {
      final label = '${option['label'] ?? option['value']}';
      final value = '${option['value'] ?? option['label']}';
      if (current == label || current == value) return label;
    }

    return '';
  }
}

class _DeviceBadge extends StatelessWidget {
  const _DeviceBadge({
    required this.label,
    required this.connected,
    required this.icon,
  });

  final String label;
  final bool connected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFE8F8EE) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: connected ? const Color(0xFF86D39D) : const Color(0xFFD6E0EF),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: connected
                ? const Color(0xFF087A4A)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? '$label Connected' : '$label Off',
            style: TextStyle(
              color: connected
                  ? const Color(0xFF087A4A)
                  : const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon({
    required this.connected,
    required this.icon,
    required this.tooltip,
  });

  final bool connected;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: connected ? '$tooltip connected' : '$tooltip not connected',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: const Color(0xFF0B57D0)),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: connected
                      ? const Color(0xFF087A4A)
                      : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleLiveBadge extends StatelessWidget {
  const _ScaleLiveBadge({required this.connected, this.compact = false});

  final bool connected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFF067A4A) : const Color(0xFFB42318),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sensors_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            connected ? 'SCALE LIVE' : 'NO SCALE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF8A9AB4),
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InlineMeasure extends StatelessWidget {
  const _InlineMeasure({
    required this.label,
    required this.value,
    this.alignRight = false,
    this.emphasized = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool alignRight;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          crossAxisAlignment: alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8A9AB4),
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF0F1B2D),
                    fontSize: emphasized ? 22 : 16,
                    fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.edit_outlined, size: 15),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileMeasure extends StatelessWidget {
  const _MobileMeasure({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F1B2D),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 5),
                const Icon(Icons.edit_outlined, size: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionStrip extends StatelessWidget {
  const _SessionStrip({required this.session});

  final LocalInwardSession? session;

  @override
  Widget build(BuildContext context) {
    final active = session?.status == 'open';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD6E0EF)),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.play_circle_outline : Icons.info_outline,
            color: active ? const Color(0xFF0B57D0) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active
                  ? '${session!.sessionNumber}  |  ${session!.entryCount} entries  |  ${session!.totalNetWeight.toStringAsFixed(3)} kg'
                  : 'Start an inward session before saving weight',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0FC),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 22,
        vertical: compact ? 12 : 14,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              compact ? 'SERIAL NO' : 'SERIAL NO',
              style: _headerStyle(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'WEIGHT',
              textAlign: TextAlign.center,
              style: _headerStyle(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'TIME',
              textAlign: TextAlign.end,
              style: _headerStyle(),
            ),
          ),
          SizedBox(width: compact ? 42 : 40),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      color: Color(0xFF334155),
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.row,
    required this.compact,
    required this.onDelete,
  });

  final LocalProductionTransaction row;
  final bool compact;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time =
        '${row.capturedAt.hour.toString().padLeft(2, '0')}:${row.capturedAt.minute.toString().padLeft(2, '0')}:${row.capturedAt.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 18,
        vertical: compact ? 14 : 8,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              compact ? '#${row.serialNumber}' : row.serialNumber,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              compact
                  ? '${row.netWeight.toStringAsFixed(3)}\nkg'
                  : '${row.netWeight.toStringAsFixed(3)} kg',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF0F1B2D),
                fontSize: compact ? 16 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              time,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: compact ? 42 : 40,
            height: compact ? 42 : 36,
            child: IconButton(
              tooltip: 'Delete mistaken weighment',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Color(0xFFB42318)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      height: 76,
      onDestinationSelected: (index) {
        final routes = ['/weighing', '/reports', '/products', '/'];
        context.go(routes[index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.monitor_weight_outlined),
          selectedIcon: Icon(Icons.monitor_weight),
          label: 'Weigh',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Products',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
