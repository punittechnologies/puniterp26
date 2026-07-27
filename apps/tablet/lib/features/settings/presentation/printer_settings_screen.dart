import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_edition.dart';
import '../../../services/devices/app_device_session.dart';
import '../../../services/devices/bluetooth_thermal_printer_adapter.dart';
import '../../../services/devices/printer_adapter.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late final BluetoothThermalPrinterAdapter adapter;

  List<PrinterDevice> printers = [];
  PrinterDevice? selectedPrinter;
  PrinterConnectionStatus status = PrinterConnectionStatus.disconnected;
  String message =
      'Scan/list printers: BLE TSPL, TVS Native Bluetooth, TSC USB, or TSC USB-Serial.';

  @override
  void initState() {
    super.initState();
    adapter = AppEdition.webManagedLabels
        ? AppDeviceSession.instance.printerAdapter
        : BluetoothThermalPrinterAdapter();
    _load();
  }

  Future<void> _load() async {
    selectedPrinter = await adapter.savedPrinter();
    await _refresh();
    if (mounted) setState(() {});
  }

  Future<void> _requestPermissions() async {
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    setState(() {
      message = connect.isGranted && scan.isGranted
          ? 'Bluetooth printer permissions granted.'
          : 'Bluetooth permission required. Enable it from Android settings.';
    });
    if (connect.isPermanentlyDenied || scan.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _refresh() async {
    try {
      setState(() => status = PrinterConnectionStatus.listing);
      final list = await adapter.discover();
      setState(() {
        printers = list;
        selectedPrinter = printers.contains(selectedPrinter)
            ? selectedPrinter
            : null;
        status = PrinterConnectionStatus.disconnected;
        message = list.isEmpty
            ? 'No printers found. For Bluetooth pair first; for TSC USB/Serial connect OTG cable and allow USB permission.'
            : 'Found ${list.length} printer option(s): Bluetooth, USB, and/or Serial.';
      });
      final connected = await adapter.isConnected();
      if (mounted && connected) {
        setState(() {
          status = PrinterConnectionStatus.connected;
          message = selectedPrinter == null
              ? 'Printer remains connected.'
              : 'Connected to ${selectedPrinter!.name}.';
        });
      }
    } catch (error) {
      setState(() {
        status = PrinterConnectionStatus.error;
        message = 'Could not list printers: $error';
      });
    }
  }

  Future<void> _connect() async {
    final printer = selectedPrinter;
    if (printer == null) {
      setState(() => message = 'Select a printer first.');
      return;
    }

    try {
      setState(() => status = PrinterConnectionStatus.connecting);
      await adapter.connect(printer.id);
      await adapter.savePrinter(printer);
      setState(() {
        status = PrinterConnectionStatus.connected;
        message = 'Connected to ${printer.name}.';
      });
    } catch (error) {
      setState(() {
        status = PrinterConnectionStatus.error;
        message = 'Connection failed: $error';
      });
    }
  }

  Future<void> _disconnect() async {
    await adapter.disconnect();
    setState(() {
      status = PrinterConnectionStatus.disconnected;
      message = 'Printer disconnected.';
    });
  }

  Future<void> _forget() async {
    await adapter.disconnect();
    await adapter.forgetPrinter();
    setState(() {
      selectedPrinter = null;
      status = PrinterConnectionStatus.disconnected;
      message = 'Saved printer forgotten.';
    });
  }

  Future<void> _testPrint() async {
    try {
      setState(() => status = PrinterConnectionStatus.printing);
      final result = await adapter.print(
        PrintJob(
          jobId: 'test_${DateTime.now().microsecondsSinceEpoch}',
          template: const {},
          data: {
            'company_name': 'Punit Weighing',
            'product_name': 'Printer Test Label',
            'serial_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
            'barcode_value': 'TEST123456',
            'gross_weight': 12.345,
            'tare_weight': 0.500,
            'net_weight': 11.845,
            'unit': 'kg',
            'piece_quantity': 24,
            'dynamic_values': {'SIZE': '16', 'COLOR': 'BLUE'},
          },
        ),
      );
      setState(() {
        status = result.status == 'printed'
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.error;
        message = result.message ?? result.status;
      });
    } catch (error) {
      setState(() {
        status = PrinterConnectionStatus.error;
        message = 'Test print failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Printer Settings'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final content = [
            _statusCard(),
            const SizedBox(height: 16),
            _controls(),
            const SizedBox(height: 16),
            _printerPicker(),
            const SizedBox(height: 16),
            _actions(),
          ];

          return ListView(
            padding: EdgeInsets.all(compact ? 14 : 24),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Printer: ${status.name}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            const Text(
              'TSC TA-210 / TA-244 use TSPL. USB serial defaults to 9600 baud, 8-N-1.',
              style: TextStyle(color: Colors.black54),
            ),
            if (selectedPrinter != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${selectedPrinter!.name} (${selectedPrinter!.address ?? selectedPrinter!.id})',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: _requestPermissions,
          child: const Text('Request Permissions'),
        ),
        OutlinedButton(
          onPressed: _refresh,
          child: const Text('Scan / List Printers'),
        ),
      ],
    );
  }

  Widget _printerPicker() {
    return DropdownButtonFormField<PrinterDevice>(
      initialValue: printers.contains(selectedPrinter) ? selectedPrinter : null,
      decoration: const InputDecoration(
        labelText: 'Selected printer connection',
        border: OutlineInputBorder(),
      ),
      items: printers
          .map(
            (printer) => DropdownMenuItem(
              value: printer,
              child: Text('${printer.name}  ${printer.address ?? ''}'),
            ),
          )
          .toList(),
      onChanged: (printer) => setState(() => selectedPrinter = printer),
    );
  }

  Widget _actions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: selectedPrinter == null ? null : _connect,
          child: const Text('Connect & Save'),
        ),
        OutlinedButton(
          onPressed: status == PrinterConnectionStatus.connected
              ? _testPrint
              : null,
          child: const Text('Print Test Label'),
        ),
        OutlinedButton(
          onPressed: status == PrinterConnectionStatus.connected
              ? _disconnect
              : null,
          child: const Text('Disconnect'),
        ),
        TextButton(
          onPressed: selectedPrinter == null ? null : _forget,
          child: const Text('Forget Printer'),
        ),
      ],
    );
  }
}
