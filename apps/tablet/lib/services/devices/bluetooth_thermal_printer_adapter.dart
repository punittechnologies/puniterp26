import 'dart:async';
import 'dart:convert' show ascii, base64Decode, jsonDecode, jsonEncode;
import 'dart:io';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_edition.dart';
import 'printer_adapter.dart';

class BluetoothThermalPrinterAdapter implements PrinterAdapter {
  BluetoothThermalPrinterAdapter({bool? qrPrintingEnabled})
    : qrPrintingEnabled = qrPrintingEnabled ?? AppEdition.webManagedLabels;

  static const _savedPrinterKey = 'printer.selected.ble_tspl';
  static const _savedCharacteristicKey = 'printer.selected.ble_characteristic';
  static const _tvsChannel = MethodChannel('punit.erp/tvs_printer');
  static const _tscChannel = MethodChannel('punit.erp/tsc_printer');
  static const _scanTimeout = Duration(seconds: 8);
  static const _connectTimeout = Duration(seconds: 14);
  static const _writeChunkSize = 20;

  final bool qrPrintingEnabled;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  String? _connectedDeviceId;
  bool _nativeConnected = false;
  bool _tscConnected = false;

  Future<PrinterDevice?> savedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedPrinterKey);
    if (raw == null) return null;

    return PrinterDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePrinter(PrinterDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPrinterKey, jsonEncode(device.toJson()));
  }

  Future<void> forgetPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPrinterKey);
    await prefs.remove(_savedCharacteristicKey);
  }

  @override
  Future<List<PrinterDevice>> discover() async {
    final devices = <String, PrinterDevice>{};
    Object? bleError;

    try {
      await _ensureBleReady(scan: true);
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final id = 'ble:${result.device.remoteId.str}';
          final name = _displayName(
            result.device,
            result.advertisementData.advName,
          );
          if (name.isEmpty && result.advertisementData.serviceUuids.isEmpty) {
            continue;
          }
          devices[id] = PrinterDevice(
            id: id,
            name:
                '[BLE TSPL] ${name.isEmpty ? result.device.remoteId.str : name}',
            address: result.device.remoteId.str,
          );
        }
      });

      try {
        await FlutterBluePlus.stopScan();
        await FlutterBluePlus.startScan(
          timeout: _scanTimeout,
          androidUsesFineLocation: false,
        );
        await Future<void>.delayed(
          _scanTimeout + const Duration(milliseconds: 300),
        );
      } finally {
        await FlutterBluePlus.stopScan();
        await subscription.cancel();
      }
    } catch (error) {
      bleError = error;
    }

    final saved = await savedPrinter();
    if (saved != null) {
      devices.putIfAbsent(saved.id, () => saved);
    }

    if (Platform.isAndroid) {
      for (final device in await _nativePairedDevices()) {
        devices.putIfAbsent(device.id, () => device);
      }
      for (final device in await _tscDevices()) {
        devices.putIfAbsent(device.id, () => device);
      }
    }

    if (devices.isEmpty && bleError != null) {
      throw StateError(
        'No printers found. BLE scan failed: $bleError. Pair the TVS printer in Android Bluetooth settings, then scan again.',
      );
    }

    final list = devices.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Future<void> connect(String deviceIdentifier) async {
    if (_isNativeId(deviceIdentifier)) {
      await _connectNative(_rawDeviceId(deviceIdentifier));
      _connectedDeviceId = deviceIdentifier;
      return;
    }
    if (_isTscId(deviceIdentifier)) {
      await _connectTsc(deviceIdentifier);
      _connectedDeviceId = deviceIdentifier;
      return;
    }

    await _ensureBleReady(scan: false);

    final bleId = _rawDeviceId(deviceIdentifier);
    if (_connectedDeviceId == deviceIdentifier &&
        _device != null &&
        _writeCharacteristic != null &&
        await isConnected()) {
      return;
    }

    await disconnect();

    final device = BluetoothDevice.fromId(bleId);
    await device
        .connect(autoConnect: false, timeout: _connectTimeout)
        .timeout(_connectTimeout);

    if (Platform.isAndroid) {
      try {
        await device.requestMtu(247).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Some printers reject MTU negotiation; 20-byte chunks still work.
      }
    }

    final services = await device.discoverServices();
    final characteristic = await _findWritableCharacteristic(bleId, services);
    if (characteristic == null) {
      await device.disconnect();
      throw StateError('No BLE write characteristic found on this printer.');
    }

    _device = device;
    _writeCharacteristic = characteristic;
    _connectedDeviceId = deviceIdentifier;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedCharacteristicKey,
      '${characteristic.serviceUuid.str}|${characteristic.characteristicUuid.str}',
    );
  }

  @override
  Future<void> disconnect() async {
    if (Platform.isAndroid) {
      try {
        await _tvsChannel.invokeMethod<bool>('disconnect');
      } catch (_) {
        // Native printer may not be initialised.
      }
      try {
        await _tscChannel.invokeMethod<bool>('disconnect');
      } catch (_) {
        // TSC printer may not be initialised.
      }
    }
    _nativeConnected = false;
    _tscConnected = false;

    final device = _device;
    _device = null;
    _writeCharacteristic = null;
    _connectedDeviceId = null;
    if (device != null) {
      try {
        await device.disconnect();
      } catch (_) {
        // Already disconnected.
      }
    }
  }

  @override
  Future<bool> isConnected() async {
    if (_nativeConnected && Platform.isAndroid) {
      final connected = await _tvsChannel.invokeMethod<bool>('isConnected');
      return connected ?? false;
    }
    if (_tscConnected && Platform.isAndroid) {
      final connected = await _tscChannel.invokeMethod<bool>('isConnected');
      return connected ?? false;
    }
    final device = _device;
    if (device == null) return false;
    return device.isConnected;
  }

  @override
  Future<PrintResult> print(PrintJob job) async {
    if (_nativeConnected && Platform.isAndroid) {
      return _printNative(job);
    }
    if (_tscConnected && Platform.isAndroid) {
      return _printTsc(job);
    }

    if (!await isConnected()) {
      return PrintResult(
        jobId: job.jobId,
        status: 'failed',
        message: 'Printer not connected',
      );
    }

    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      return PrintResult(
        jobId: job.jobId,
        status: 'failed',
        message: 'Printer write channel is not ready. Reconnect printer.',
      );
    }

    final bytes = _tsplBytes(job);
    try {
      await _writeChunks(characteristic, bytes);
      return PrintResult(
        jobId: job.jobId,
        status: 'printed',
        message:
            'TSPL label sent over BLE. If paper does not move, confirm printer is in TSPL/BPLZ label mode.',
      );
    } catch (error) {
      return PrintResult(
        jobId: job.jobId,
        status: 'failed',
        message: 'Printer connected, but write failed: $error',
      );
    }
  }

  Future<List<PrinterDevice>> _nativePairedDevices() async {
    try {
      final raw = await _tvsChannel.invokeMethod<List<dynamic>>(
        'pairedDevices',
      );
      return (raw ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((item) {
            final address = item['address']?.toString() ?? '';
            final name = item['name']?.toString() ?? address;
            return PrinterDevice(
              id: 'tvs:$address',
              name: '[TVS Native] $name',
              address: address,
            );
          })
          .where((device) => device.address?.isNotEmpty == true)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<PrinterDevice>> _tscDevices() async {
    try {
      final raw = await _tscChannel.invokeMethod<List<dynamic>>('devices');
      return (raw ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => PrinterDevice(
              id: item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? 'TSC Printer',
              address: item['address']?.toString(),
            ),
          )
          .where((device) => device.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _connectNative(String address) async {
    await _ensureNativeReady();
    await disconnect();
    final response = await _tvsChannel.invokeMethod<Map<dynamic, dynamic>>(
      'connect',
      {'address': address, 'language': 6},
    );
    final ok = response?['ok'] == true;
    if (!ok) {
      throw StateError(
        response?['message']?.toString() ??
            'TVS native printer connection failed.',
      );
    }
    _nativeConnected = true;
    _tscConnected = false;
  }

  Future<void> _connectTsc(String deviceIdentifier) async {
    await disconnect();
    final response = await _tscChannel.invokeMethod<Map<dynamic, dynamic>>(
      'connect',
      {'id': deviceIdentifier, 'baudRate': _tscBaudRate(deviceIdentifier)},
    );
    final ok = response?['ok'] == true;
    if (!ok) {
      throw StateError(
        response?['message']?.toString() ?? 'TSC printer connection failed.',
      );
    }
    _tscConnected = true;
    _nativeConnected = false;
  }

  Future<PrintResult> _printNative(PrintJob job) async {
    try {
      final response = await _tvsChannel.invokeMethod<Map<dynamic, dynamic>>(
        'printRawTsplBytes',
        {'bytes': _tsplBytes(job)},
      );
      final ok = response?['ok'] == true;
      return PrintResult(
        jobId: job.jobId,
        status: ok ? 'printed' : 'failed',
        message:
            response?['message']?.toString() ??
            (ok ? 'TVS native label sent.' : 'TVS native print failed.'),
      );
    } catch (error) {
      return PrintResult(
        jobId: job.jobId,
        status: 'failed',
        message: 'TVS native print failed: $error',
      );
    }
  }

  Future<PrintResult> _printTsc(PrintJob job) async {
    try {
      final response = await _tscChannel.invokeMethod<Map<dynamic, dynamic>>(
        'printRawTsplBytes',
        {'bytes': _tsplBytes(job)},
      );
      final ok = response?['ok'] == true;
      return PrintResult(
        jobId: job.jobId,
        status: ok ? 'printed' : 'failed',
        message:
            response?['message']?.toString() ??
            (ok ? 'TSC label sent.' : 'TSC print failed.'),
      );
    } catch (error) {
      return PrintResult(
        jobId: job.jobId,
        status: 'failed',
        message: 'TSC print failed: $error',
      );
    }
  }

  Future<void> _ensureBleReady({required bool scan}) async {
    final permissions = <Permission>[
      Permission.bluetoothConnect,
      if (scan) Permission.bluetoothScan,
      if (Platform.isAndroid) Permission.locationWhenInUse,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted && !status.isLimited) {
        throw StateError('Bluetooth permission required for printer.');
      }
    }

    if (!await FlutterBluePlus.isSupported) {
      throw StateError('BLE is not supported on this Android device.');
    }

    final adapterState = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(seconds: 3),
      onTimeout: () => BluetoothAdapterState.unknown,
    );
    if (adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn(timeout: 8);
        } catch (_) {
          throw StateError('Bluetooth is off. Turn it on and try again.');
        }
      } else {
        throw StateError('Bluetooth is off. Turn it on and try again.');
      }
    }
  }

  Future<void> _ensureNativeReady() async {
    final status = await Permission.bluetoothConnect.request();
    if (!status.isGranted && !status.isLimited) {
      throw StateError(
        'Bluetooth connect permission required for TVS native printer.',
      );
    }

    if (Platform.isAndroid) {
      final adapterState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => BluetoothAdapterState.unknown,
      );
      if (adapterState != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn(timeout: 8);
        } catch (_) {
          throw StateError('Bluetooth is off. Turn it on and try again.');
        }
      }
    }
  }

  bool _isNativeId(String id) => id.startsWith('tvs:');

  bool _isTscId(String id) =>
      id.startsWith('tsc_usb:') || id.startsWith('tsc_serial:');

  String _rawDeviceId(String id) {
    if (id.startsWith('ble:') || id.startsWith('tvs:')) {
      return id.substring(4);
    }
    return id;
  }

  int _tscBaudRate(String id) {
    if (id.contains('@')) {
      return int.tryParse(id.split('@').last) ?? 9600;
    }
    return 9600;
  }

  Future<BluetoothCharacteristic?> _findWritableCharacteristic(
    String deviceId,
    List<BluetoothService> services,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_savedCharacteristicKey);
    if (saved != null) {
      final parts = saved.split('|');
      if (parts.length == 2) {
        for (final service in services) {
          if (service.serviceUuid.str.toLowerCase() != parts[0].toLowerCase()) {
            continue;
          }
          for (final characteristic in service.characteristics) {
            if (characteristic.characteristicUuid.str.toLowerCase() ==
                    parts[1].toLowerCase() &&
                _canWrite(characteristic)) {
              return characteristic;
            }
          }
        }
      }
    }

    final writable = <BluetoothCharacteristic>[];
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (_canWrite(characteristic)) {
          writable.add(characteristic);
        }
      }
    }

    if (writable.isEmpty) return null;

    writable.sort((a, b) {
      final aScore = _characteristicScore(a);
      final bScore = _characteristicScore(b);
      return bScore.compareTo(aScore);
    });
    return writable.first;
  }

  bool _canWrite(BluetoothCharacteristic characteristic) {
    return characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;
  }

  int _characteristicScore(BluetoothCharacteristic characteristic) {
    final uuid = characteristic.characteristicUuid.str.toLowerCase();
    var score = 0;
    if (characteristic.properties.writeWithoutResponse) score += 4;
    if (characteristic.properties.write) score += 3;
    if (uuid.contains('ffe1') || uuid.contains('ff02')) score += 5;
    if (uuid.contains('ae01') || uuid.contains('ae02')) score += 3;
    return score;
  }

  Future<void> _writeChunks(
    BluetoothCharacteristic characteristic,
    List<int> bytes,
  ) async {
    final withoutResponse = characteristic.properties.writeWithoutResponse;
    for (var offset = 0; offset < bytes.length; offset += _writeChunkSize) {
      final end = (offset + _writeChunkSize).clamp(0, bytes.length);
      final chunk = bytes.sublist(offset, end);
      await characteristic
          .write(chunk, withoutResponse: withoutResponse)
          .timeout(const Duration(seconds: 4));
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  String _displayName(BluetoothDevice device, String advertisedName) {
    final platformName = device.platformName.trim();
    if (platformName.isNotEmpty) return platformName;
    return advertisedName.trim();
  }

  Uint8List _tsplBytes(PrintJob job) {
    final template = job.template;
    final widthMm = _num(template['widthMm'])?.round() ?? 75;
    final heightMm = _num(template['heightMm'])?.round() ?? 75;
    final elements = (template['elements'] is List)
        ? (template['elements'] as List).whereType<Map>().toList()
        : const <Map>[];
    if (elements.isNotEmpty) {
      return _encodeTsplParts(
        _tsplFromTemplateParts(job, widthMm, heightMm, elements),
      );
    }

    return Uint8List.fromList(ascii.encode(_tspl(job)));
  }

  String _tspl(PrintJob job) {
    final data = job.data;
    final template = job.template;
    final widthMm = _num(template['widthMm'])?.round() ?? 75;
    final heightMm = _num(template['heightMm'])?.round() ?? 75;
    final elements = (template['elements'] is List)
        ? (template['elements'] as List).whereType<Map>().toList()
        : const <Map>[];
    if (elements.isNotEmpty) {
      return _tsplFromTemplate(job, widthMm, heightMm, elements);
    }

    final dynamicValues = data['dynamic_values'];
    final fieldLines = <MapEntry<String, String>>[];
    if (dynamicValues is Map) {
      for (final entry in dynamicValues.entries) {
        final value = _clean(entry.value);
        if (value.isNotEmpty) {
          fieldLines.add(MapEntry(_label(entry.key), value));
        }
      }
    }

    final product = _clean(data['product_name']).ifEmpty('Product');
    final serial = _clean(data['serial_number']).ifEmpty('PREVIEW');
    final barcode = _clean(data['barcode_value']).ifEmpty(serial);
    final unit = _clean(data['unit']).ifEmpty('kg');
    final pieces = _clean(data['piece_quantity']);
    final lines = <String>[
      'SIZE $widthMm mm,$heightMm mm',
      'GAP 2 mm,0 mm',
      'DENSITY 14',
      'SPEED 3',
      'DIRECTION 1',
      'REFERENCE 0,0',
      'CODEPAGE UTF-8',
      'CLS',
      _text(
        34,
        28,
        '3',
        1,
        1,
        _clean(data['company_name']).ifEmpty('PUNIT ERP'),
      ),
      _text(34, 62, '3', 1, 1, 'SN: ${_limit(serial, 22)}'),
      _text(34, 100, '3', 2, 2, _limit(product, 18)),
      'BAR 34,172,526,2',
      _text(
        34,
        190,
        '3',
        1,
        1,
        'Gross: ${_weight(data['gross_weight'], unit)}',
      ),
      _text(300, 190, '3', 1, 1, 'Tare: ${_weight(data['tare_weight'], unit)}'),
      _text(34, 228, '3', 2, 2, 'Net ${_weight(data['net_weight'], unit)}'),
      if (pieces.isNotEmpty)
        _text(300, 240, '3', 1, 1, 'PCS: ${_limit(pieces, 12)}'),
      'BAR 34,290,526,2',
      ..._fieldTspl(fieldLines.take(10).toList(), startY: 307),
      if (barcode.isNotEmpty)
        'BARCODE 58,500,"128",34,0,0,2,2,"${_limit(barcode, 28)}"',
      if (barcode.isNotEmpty) _text(58, 540, '1', 1, 1, _limit(barcode, 24)),
      'PRINT 1,1',
      '',
    ];

    return '${lines.join('\r\n')}\r\n';
  }

  String _tsplFromTemplate(
    PrintJob job,
    int widthMm,
    int heightMm,
    List<Map> elements,
  ) {
    return _debugTsplParts(
      _tsplFromTemplateParts(job, widthMm, heightMm, elements),
    );
  }

  List<Object> _tsplFromTemplateParts(
    PrintJob job,
    int widthMm,
    int heightMm,
    List<Map> elements,
  ) {
    final data = job.data;
    final lines = <Object>[
      'SIZE $widthMm mm,$heightMm mm',
      'GAP 2 mm,0 mm',
      'DENSITY 14',
      'SPEED 3',
      'DIRECTION 1',
      'REFERENCE 0,0',
      'CODEPAGE UTF-8',
      'CLS',
    ];

    final ordered = [...elements]
      ..sort(
        (a, b) => ((_num(a['layerOrder']) ?? 0).compareTo(
          _num(b['layerOrder']) ?? 0,
        )),
      );

    var hasBarcode = false;
    for (final element in ordered) {
      final type = element['type']?.toString();
      if (type == 'qr' || type == 'qrcode') {
        if (!qrPrintingEnabled) {
          continue;
        }
        final value = _bindingValue(
          element['bindingKey']?.toString() ?? 'qr.value',
          data,
        );
        if (value.isEmpty) {
          continue;
        }
        final widthDots = _dots(element['width']).clamp(48, 832);
        final heightDots = _dots(element['height']).clamp(48, 832);
        final cellWidth = (min(widthDots, heightDots) ~/ 45).clamp(2, 8);
        final estimatedSize = cellWidth * 45;
        final x =
            _dots(element['x']) +
            ((widthDots - estimatedSize).clamp(0, widthDots) ~/ 2);
        final y =
            _dots(element['y']) +
            ((heightDots - estimatedSize).clamp(0, heightDots) ~/ 2);
        final rotation = _qrRotation(_num(element['rotation']) ?? 0);
        lines.add(
          'QRCODE $x,$y,M,$cellWidth,A,$rotation,M2,S7,"${_escape(value)}"',
        );
        continue;
      }

      if (type == 'barcode') {
        hasBarcode = true;
        final barcode = _clean(
          data['barcode_value'],
        ).ifEmpty(_clean(data['serial_number']).ifEmpty('PREVIEW'));
        final barcodeLayout = _barcodeLayout(element, barcode);
        lines.add(
          'BARCODE ${barcodeLayout.x},${_dots(element['y'])},"128",'
          '${_dots(element['height']).clamp(28, 72)},0,0,'
          '${barcodeLayout.moduleWidth},${barcodeLayout.moduleWidth},'
          '"${_limit(barcode, 28)}"',
        );
        final valueFontSize = 8;
        final value = _limit(barcode, 24);
        lines.add(
          _text(
            _alignedX(element, value, valueFontSize, 'center', ''),
            _dots(
              (_num(element['y']) ?? 0) + (_num(element['height']) ?? 16) + 1,
            ),
            '1',
            1,
            1,
            _limit(barcode, 24),
          ),
        );
        continue;
      }

      if (type == 'rectangle') {
        final border = (element['border'] as Map?) ?? const {};
        final thicknessMm = _num(border['width']) ?? .35;
        final x = _dots(element['x']);
        final y = _dots(element['y']);
        final x2 = _dots(
          (_num(element['x']) ?? 0) + (_num(element['width']) ?? 0),
        );
        final y2 = _dots(
          (_num(element['y']) ?? 0) + (_num(element['height']) ?? 0),
        );
        lines.add('BOX $x,$y,$x2,$y2,${_dots(thicknessMm).clamp(1, 4)}');
        continue;
      }

      if (type == 'image') {
        final bitmap = _imageBitmapTspl(element);
        if (bitmap != null) {
          lines.add(bitmap);
        }
        continue;
      }

      if (type != 'text' && type != 'static_text' && type != 'binding_text') {
        continue;
      }

      final style = (element['style'] as Map?) ?? const {};
      final fontSize = _num(style['fontSize']) ?? 9;
      final weight = style['fontWeight']?.toString() ?? '';
      final align = style['align']?.toString() ?? 'left';
      final prefix = _affix(element['prefix']);
      final suffix = _affix(element['suffix']);
      final value = type == 'binding_text'
          ? _bindingValue(element['bindingKey']?.toString(), data)
          : _clean(element['text']).ifEmpty(_clean(element['bindingKey']));
      if (value.isEmpty) continue;

      final text = '$prefix$value$suffix';
      final limitedText = _limit(
        text,
        _charsForWidth(
          (_num(element['width']) ?? widthMm).toDouble(),
          fontSize,
          weight,
        ),
      );
      // A browser can style prefix/value/suffix independently, but TVS/TSPL
      // built-in fonts do not expose reliable glyph metrics. Sending the three
      // parts as separate TEXT commands made the calculated cursors overlap on
      // real 203-DPI printers. Keep each field atomic so the printer advances
      // its own cursor and the physical output matches the single-line preview.
      lines.add(
        _text(
          _alignedX(element, limitedText, fontSize, align, weight),
          _dots(element['y']),
          _fontName(fontSize, weight),
          _fontMultiplier(fontSize),
          _fontMultiplier(fontSize),
          limitedText,
        ),
      );
    }

    if (!hasBarcode) {
      final barcode = _clean(data['barcode_value']).ifEmpty('PREVIEW');
      lines.add(
        'BARCODE ${_dots(5)},${_dots(heightMm - 20)},"128",34,0,0,2,2,"${_limit(barcode, 28)}"',
      );
      lines.add(
        _text(_dots(5), _dots(heightMm - 7), '1', 1, 1, _limit(barcode, 28)),
      );
    }

    lines.addAll(['PRINT 1,1', '']);
    return lines;
  }

  Uint8List _encodeTsplParts(List<Object> parts) {
    final bytes = <int>[];
    for (final part in parts) {
      if (part is _BitmapTspl) {
        bytes.addAll(ascii.encode(part.prefix));
        bytes.addAll(part.data);
      } else {
        bytes.addAll(ascii.encode(part.toString()));
      }
      bytes.addAll(const [13, 10]);
    }
    return Uint8List.fromList(bytes);
  }

  String _debugTsplParts(List<Object> parts) {
    final lines = parts.map((part) {
      if (part is _BitmapTspl) {
        return '${part.prefix}<${part.data.length} bitmap bytes>';
      }
      return part.toString();
    });
    return '${lines.join('\r\n')}\r\n';
  }

  Iterable<String> _fieldTspl(
    List<MapEntry<String, String>> fields, {
    required int startY,
  }) sync* {
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      final x = index.isEven ? 34 : 304;
      final y = startY + ((index ~/ 2) * 35);
      yield _text(
        x,
        y,
        '1',
        1,
        1,
        '${_limit(field.key, 9)}: ${_limit(field.value, 15)}',
      );
    }
  }

  String _text(int x, int y, String font, int xMul, int yMul, String value) {
    return 'TEXT $x,$y,"$font",0,$xMul,$yMul,"${_escape(value)}"';
  }

  String _fontName(num fontSize, String weight) {
    if (fontSize >= 11 ||
        weight == 'bold' ||
        weight == '700' ||
        weight == '800') {
      return '3';
    }
    return '1';
  }

  int _fontMultiplier(num fontSize) => fontSize >= 13 ? 2 : 1;

  int _estimatedTextWidthDots(String text, num fontSize, [String weight = '']) {
    final font = _fontName(fontSize, weight);
    final baseCharacterWidth = switch (font) {
      '1' => 8,
      '2' => 12,
      '3' => 16,
      '4' => 24,
      '5' => 32,
      _ => 8,
    };
    return text.length * baseCharacterWidth * _fontMultiplier(fontSize);
  }

  String _weight(Object? value, String unit) {
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed == null) return '0.000 $unit';
    return '${parsed.toStringAsFixed(3)} $unit';
  }

  String _bindingValue(String? key, Map<String, dynamic> data) {
    final unit = _clean(data['unit']).ifEmpty('kg');
    return switch (key) {
      'company.name' => _clean(data['company_name']).ifEmpty('PUNIT ERP'),
      'product.name' => _clean(data['product_name']),
      'variant.name' => _clean(data['variant_name']),
      'weight.gross' => _weightNumber(data['gross_weight']),
      'weight.tare' => _weightNumber(data['tare_weight']),
      'weight.net' => _weightNumber(data['net_weight']),
      'pieces.quantity' => _clean(data['piece_quantity']),
      'serial.number' => _clean(data['serial_number']),
      'barcode.value' => _clean(data['barcode_value']),
      'qr.value' => _clean(data['qr_value']),
      'date.current' => DateTime.now().toIso8601String().substring(0, 10),
      'time.current' => DateTime.now().toIso8601String().substring(11, 16),
      'operator.name' => _clean(data['operator_name']).ifEmpty('-'),
      _ when key?.startsWith('dynamic.') == true => _dynamicValue(key!, data),
      _ => key == null ? '' : _clean(data[key]).ifEmpty(unit == '' ? '' : ''),
    };
  }

  String _dynamicValue(String key, Map<String, dynamic> data) {
    final dynamicValues = data['dynamic_values'];
    final internalKey = key.split('.').last;
    if (dynamicValues is Map) {
      final value = _clean(
        dynamicValues[internalKey],
      ).ifEmpty(_clean(dynamicValues[key]));
      if (value.isNotEmpty) return value;
    }

    final productRaw = data['product_raw'];
    if (productRaw is Map) {
      final metadata = productRaw['metadata'];
      final customFields = productRaw['custom_fields'];
      final value = _clean(productRaw[internalKey])
          .ifEmpty(metadata is Map ? _clean(metadata[internalKey]) : '')
          .ifEmpty(
            customFields is Map ? _clean(customFields[internalKey]) : '',
          );
      if (value.isNotEmpty) return value;
    }

    return '-';
  }

  String _weightNumber(Object? value) {
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed == null) return '0.000';
    return parsed.toStringAsFixed(3);
  }

  int _qrRotation(num value) {
    final normalized = ((value.round() % 360) + 360) % 360;
    if (normalized >= 315 || normalized < 45) return 0;
    if (normalized < 135) return 90;
    if (normalized < 225) return 180;
    return 270;
  }

  int _dots(Object? mm) => ((_num(mm) ?? 0) * 8).round();

  int _alignedX(
    Map element,
    String text,
    num fontSize,
    String align, [
    String weight = '',
  ]) {
    return _alignedXForWidth(
      element,
      _estimatedTextWidthDots(text, fontSize, weight),
      align,
    );
  }

  int _alignedXForWidth(Map element, int contentWidth, String align) {
    final x = _dots(element['x']);
    final width = _dots(element['width']);
    if (align == 'left') return x;

    final spare = (width - contentWidth).clamp(0, width);
    if (align == 'right') return x + spare;
    return x + (spare ~/ 2);
  }

  _BarcodeLayout _barcodeLayout(Map element, String value) {
    final boxX = _dots(element['x']);
    final boxWidth = _dots(element['width']).clamp(1, 832);
    final modules = _estimatedCode128Modules(_limit(value, 28));
    final moduleWidth = (boxWidth ~/ modules).clamp(1, 2);
    final printedWidth = modules * moduleWidth;
    final x = boxX + ((boxWidth - printedWidth).clamp(0, boxWidth) ~/ 2);
    return _BarcodeLayout(x, moduleWidth);
  }

  int _estimatedCode128Modules(String value) {
    // Start, one symbol per Code Set B character, checksum, stop and quiet zones.
    // The printer may compact numeric runs into Code Set C, which only makes the
    // barcode slightly narrower; this conservative estimate keeps it inside and
    // centred within the web-designed element box.
    return (11 * (value.length + 2)) + 13 + 20;
  }

  _BitmapTspl? _imageBitmapTspl(Map element) {
    final path = element['imagePath']?.toString();
    var encoded = element['imageBase64']?.toString();
    final dataUri =
        element['imageDataUri']?.toString() ?? element['imageUrl']?.toString();
    if ((encoded == null || encoded.isEmpty) &&
        dataUri != null &&
        dataUri.contains('base64,')) {
      encoded = dataUri.substring(dataUri.indexOf('base64,') + 7);
    }
    final List<int>? bytes;
    try {
      bytes = encoded != null && encoded.isNotEmpty
          ? base64Decode(encoded)
          : path != null && path.isNotEmpty && File(path).existsSync()
          ? File(path).readAsBytesSync()
          : null;
    } catch (_) {
      return null;
    }
    if (bytes == null) return null;
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return null;

    final x = _dots(element['x']);
    final y = _dots(element['y']);
    final width = _dots(element['width']).clamp(8, 832);
    final height = _dots(element['height']).clamp(8, 1200);
    final resized = img.copyResize(
      decoded,
      width: width,
      height: height,
      interpolation: img.Interpolation.nearest,
    );
    final bytesPerRow = ((width + 7) ~/ 8);
    final bitmapBytes = <int>[];
    for (var row = 0; row < height; row++) {
      for (var byteIndex = 0; byteIndex < bytesPerRow; byteIndex++) {
        var value = 0;
        for (var bit = 0; bit < 8; bit++) {
          final col = byteIndex * 8 + bit;
          if (col >= width) continue;
          final pixel = resized.getPixel(col, row);
          if (pixel.a < 32) continue;
          final luminance =
              (pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114);
          if (luminance < 235) {
            value |= 1 << (7 - bit);
          }
        }
        bitmapBytes.add(value);
      }
    }
    return _BitmapTspl(
      'BITMAP $x,$y,$bytesPerRow,$height,0,',
      Uint8List.fromList(bitmapBytes),
    );
  }

  num? _num(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  int _charsForWidth(double widthMm, num fontSize, [String weight = '']) {
    final widthDots = _dots(widthMm);
    final characterWidth = _estimatedTextWidthDots('M', fontSize, weight);
    return (widthDots ~/ characterWidth).clamp(1, 64);
  }

  String _label(Object? value) =>
      _clean(value).replaceAll('_', ' ').toUpperCase();

  String _clean(Object? value) {
    if (value == null) return '';
    return value
        .toString()
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _affix(Object? value) {
    if (value == null) return '';
    return value
        .toString()
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _escape(String value) => value
      .replaceAll('±', '+/-')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('’', "'")
      .replaceAll('"', '')
      .replaceAll(r'\', '/');

  String _limit(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  @visibleForTesting
  String debugTspl(PrintJob job) => _tspl(job);

  @visibleForTesting
  Uint8List debugTsplBytes(PrintJob job) => _tsplBytes(job);
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _BitmapTspl {
  const _BitmapTspl(this.prefix, this.data);

  final String prefix;
  final Uint8List data;
}

class _BarcodeLayout {
  const _BarcodeLayout(this.x, this.moduleWidth);

  final int x;
  final int moduleWidth;
}
