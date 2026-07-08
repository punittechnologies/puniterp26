import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_session.dart';
import '../../../core/database/local_database.dart';
import '../../../services/devices/android_bluetooth_settings.dart';
import '../../../services/sync/sync_queue_service.dart';
import '../data/dispatch_repository.dart';

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final database = LocalDatabase();
  late CustomerRepository customerRepository = CustomerRepository(database);
  late DispatchRepository dispatchRepository = DispatchRepository(database);
  late SyncQueueService syncQueueService = SyncQueueService(database);
  final scanner = BarcodeScannerService();
  final barcodeController = TextEditingController();
  final barcodeFocus = FocusNode();
  final bluetoothSettings = const AndroidBluetoothSettings();
  static const _draftCustomerKey = 'dispatch_draft_customer_id';
  static const _draftBarcodeKey = 'dispatch_draft_barcodes';

  List<LocalCustomer> customers = [];
  LocalCustomer? selectedCustomer;
  List<LocalProductionTransaction> scanned = [];
  List<LocalDispatche> history = [];
  String? message;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => barcodeFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    barcodeController.dispose();
    barcodeFocus.dispose();
    database.close();
    super.dispose();
  }

  Future<void> _load() async {
    final client = await ApiSession.client();
    customerRepository = CustomerRepository(database, apiClient: client);
    dispatchRepository = DispatchRepository(database, apiClient: client);
    syncQueueService = SyncQueueService(database, apiClient: client);
    await customerRepository.sync();
    await dispatchRepository.syncHistory();
    customers = await customerRepository.cachedCustomers();
    history = await dispatchRepository.history();
    await _restoreDraft();
    selectedCustomer ??= customers.firstOrNull;
    if (mounted) setState(() {});
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString(_draftCustomerKey);
    if (customerId != null) {
      selectedCustomer = customers
          .where((item) => item.id == customerId)
          .firstOrNull;
    }

    final encoded = prefs.getString(_draftBarcodeKey);
    if (encoded == null || scanned.isNotEmpty) return;
    final values = (jsonDecode(encoded) as List<dynamic>).whereType<String>();
    final restored = <LocalProductionTransaction>[];
    for (final barcode in values) {
      final item = await _findAvailableBarcodeSafely(barcode);
      if (item != null &&
          !restored.any(
            (existing) => existing.barcodeValue == item.barcodeValue,
          )) {
        restored.add(item);
      }
    }
    scanned = restored;
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final customer = selectedCustomer;
    if (customer == null && scanned.isEmpty) {
      await prefs.remove(_draftCustomerKey);
      await prefs.remove(_draftBarcodeKey);
      return;
    }
    if (customer != null) {
      await prefs.setString(_draftCustomerKey, customer.id);
    }
    await prefs.setString(
      _draftBarcodeKey,
      jsonEncode(scanned.map((item) => item.barcodeValue).toList()),
    );
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftCustomerKey);
    await prefs.remove(_draftBarcodeKey);
  }

  Future<void> _scanText(String value) async {
    final barcode = scanner.normalize(value);
    if (barcode.isEmpty) return;
    if (scanned.any((item) => item.barcodeValue == barcode)) {
      _cornerMessage('Duplicate scan rejected.', error: true);
      barcodeController.clear();
      barcodeFocus.requestFocus();
      return;
    }
    setState(() => message = 'Checking barcode on web server...');
    await syncQueueService.retryPending(passes: 4);
    final item = await _findAvailableBarcodeSafely(barcode);
    if (item == null) {
      _cornerMessage(
        'Barcode not found in synced records. Check internet or scan again.',
        error: true,
      );
      barcodeController.clear();
      barcodeFocus.requestFocus();
      return;
    }
    setState(() {
      scanned.add(item);
      barcodeController.clear();
      message = 'Added ${item.barcodeValue}';
    });
    await _saveDraft();
    final syncResult = await syncQueueService.retryPending(passes: 4);
    if (syncResult.hasFailures) {
      _cornerMessage(
        'Barcode added. Web sync still pending: ${syncResult.message}',
        error: true,
      );
    } else {
      _cornerMessage(
        'Barcode added and web sync checked: ${item.barcodeValue}',
      );
    }
    barcodeFocus.requestFocus();
  }

  Future<LocalProductionTransaction?> _findAvailableBarcodeSafely(
    String barcode,
  ) async {
    try {
      return await dispatchRepository.findAvailableBarcode(barcode);
    } on DispatchBarcodeException catch (error) {
      _cornerMessage(error.message, error: true);
      return null;
    }
  }

  Future<void> _openCameraScanner() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Scan Barcode',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code == null || code.trim().isEmpty) return;
                  Navigator.of(context).pop();
                  _scanText(code);
                },
              ),
            ),
          ],
        ),
      ),
    );
    barcodeFocus.requestFocus();
  }

  Future<void> _confirm() async {
    final customer = selectedCustomer;
    if (customer == null || scanned.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      final dispatchId = await dispatchRepository.confirmDispatch(
        customer: customer,
        items: scanned,
      );
      final dispatch = await dispatchRepository.findDispatch(dispatchId);
      final pdf = dispatch == null
          ? null
          : await _writeDispatchPdf(dispatch, customer, List.of(scanned));
      final syncResult = await syncQueueService.retryPending(passes: 4);
      setState(() {
        scanned = [];
        message = syncResult.hasFailures
            ? 'Dispatch saved locally. Web sync pending.'
            : 'Dispatch saved and synced to web.';
      });
      await _clearDraft();
      await _load();
      if (pdf != null && mounted) {
        if (syncResult.hasFailures) {
          _cornerMessage(
            'Dispatch saved locally. Web sync pending: ${syncResult.message}',
            error: true,
          );
        } else {
          _cornerMessage('Dispatch synced to web.');
        }
        await _showDispatchSaved(dispatch!, pdf);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<File> _writeDispatchPdf(
    LocalDispatche dispatch,
    LocalCustomer customer,
    List<LocalProductionTransaction> rows,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, '${dispatch.dispatchNumber}.pdf'));
    final lines = <String>[
      'PUNIT ERP - DISPATCH SLIP / PACKING LIST',
      'Dispatch: ${dispatch.dispatchNumber}',
      'Customer: ${customer.name}',
      'Date: ${dispatch.confirmedAt ?? dispatch.createdAt}',
      'Items: ${rows.length}',
      'Total Net: ${dispatch.totalWeight.toStringAsFixed(3)} kg',
      'Total PCS: ${(dispatch.totalPieces ?? 0).toStringAsFixed(0)}',
      '',
      'SR | BARCODE | SERIAL | PRODUCT | NET KG | PCS',
      ...rows.indexed.map((item) {
        final row = item.$2;
        return '${item.$1 + 1} | ${row.barcodeValue} | ${row.serialNumber} | '
            '${row.productId} | ${row.netWeight.toStringAsFixed(3)} | '
            '${row.pieceQuantity ?? '-'}';
      }),
    ];
    await file.writeAsBytes(_simplePdf(lines));
    return file;
  }

  List<int> _simplePdf(List<String> lines) {
    final textLines = lines
        .take(45)
        .map(
          (line) => line
              .replaceAll(r'\', '/')
              .replaceAll('(', '[')
              .replaceAll(')', ']'),
        )
        .toList();
    final content = StringBuffer();
    var y = 800;
    for (var index = 0; index < textLines.length; index++) {
      final size = index == 0 ? 13 : 8;
      content.writeln('BT /F1 $size Tf 28 $y Td (${textLines[index]}) Tj ET');
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

  Future<void> _showDispatchSaved(LocalDispatche dispatch, File pdf) async {
    _cornerMessage('Dispatch saved. Opening PDF: ${dispatch.dispatchNumber}');
    final result = await OpenFilex.open(pdf.path);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      _cornerMessage(
        'PDF saved, but no viewer opened it. File: ${pdf.path}',
        error: true,
      );
    }
  }

  void _cornerMessage(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        width: 340,
        backgroundColor: error
            ? const Color(0xFFB42318)
            : const Color(0xFF087A4A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = scanned.fold(0.0, (sum, item) => sum + item.netWeight);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Dispatch'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          if (compact) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _controlPanel(total),
                const SizedBox(height: 12),
                SizedBox(height: 520, child: _dispatchLists()),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 420, child: _controlPanel(total)),
                const SizedBox(width: 16),
                Expanded(child: _dispatchLists()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _controlPanel(double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<LocalCustomer>(
              initialValue: selectedCustomer,
              decoration: const InputDecoration(
                labelText: 'Customer',
                border: OutlineInputBorder(),
              ),
              items: customers
                  .map(
                    (customer) => DropdownMenuItem(
                      value: customer,
                      child: Text(customer.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedCustomer = value);
                _saveDraft();
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: barcodeController,
              focusNode: barcodeFocus,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: _scanText,
              decoration: InputDecoration(
                labelText: 'Bluetooth scanner / manual barcode',
                helperText:
                    'Pair any Bluetooth barcode scanner in keyboard mode, keep this field focused, and scan.',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Open camera scanner',
                  onPressed: _openCameraScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openCameraScanner,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('SCAN BARCODE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: bluetoothSettings.open,
                    icon: const Icon(Icons.bluetooth_searching_rounded),
                    label: const Text('PAIR SCANNER'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _scanText(barcodeController.text),
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD MANUAL SCAN'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: scanned.isEmpty || busy ? null : _confirm,
              icon: const Icon(Icons.save_alt_rounded),
              label: Text('SAVE DISPATCH (${total.toStringAsFixed(3)} kg)'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dispatchLists() {
    return Column(
      children: [
        Expanded(
          child: Card(
            child: ListView(
              children: [
                const ListTile(
                  title: Text(
                    'Current Scan List',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (scanned.isEmpty)
                  const ListTile(title: Text('No barcodes scanned yet')),
                ...scanned.map(
                  (item) => ListTile(
                    title: Text(item.barcodeValue),
                    subtitle: Text('${item.netWeight.toStringAsFixed(3)} kg'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() => scanned.remove(item));
                        _saveDraft();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: ListView(
              children: [
                const ListTile(
                  title: Text(
                    'Saved Dispatches',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (history.isEmpty)
                  const ListTile(title: Text('No dispatches saved yet')),
                ...history.map(
                  (item) => ListTile(
                    title: Text(item.dispatchNumber),
                    subtitle: Text(item.syncStatus),
                    trailing: Text('${item.totalWeight.toStringAsFixed(3)} kg'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
