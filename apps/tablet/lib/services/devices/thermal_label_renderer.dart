import 'dart:convert';

import 'printer_adapter.dart';

class ThermalLabelRenderer {
  const ThermalLabelRenderer();

  List<int> render(PrintJob job) {
    final data = job.data;
    final bytes = <int>[
      0x1B, 0x40, // init
      0x1B, 0x61, 0x01, // center
    ];

    _line(bytes, data['company_name']?.toString() ?? 'Punit Weighing');
    bytes.addAll([0x1B, 0x45, 0x01]);
    _line(bytes, data['product_name']?.toString() ?? 'Product');
    bytes.addAll([0x1B, 0x45, 0x00]);
    _line(bytes, data['variant_name']?.toString() ?? '');
    _line(bytes, '------------------------------');

    bytes.addAll([0x1B, 0x61, 0x00]); // left
    _field(bytes, 'Serial', data['serial_number']);
    _field(bytes, 'Barcode', data['barcode_value']);
    _field(bytes, 'Gross', _weight(data['gross_weight'], data['unit']));
    _field(bytes, 'Tare', _weight(data['tare_weight'], data['unit']));
    _field(bytes, 'Net', _weight(data['net_weight'], data['unit']));
    if (data['piece_quantity'] != null) {
      _field(bytes, 'PCS', data['piece_quantity']);
    }

    final dynamicValues = data['dynamic_values'];
    if (dynamicValues is Map) {
      dynamicValues.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          _field(bytes, key.toString(), value);
        }
      });
    }

    final barcode = data['barcode_value']?.toString();
    if (barcode != null && barcode.isNotEmpty) {
      bytes.addAll([0x0A, 0x1B, 0x61, 0x01]);
      _code128(bytes, barcode);
      _line(bytes, barcode);
    }

    bytes.addAll([0x0A, 0x0A, 0x0A, 0x1D, 0x56, 0x00]);
    return bytes;
  }

  void _field(List<int> bytes, String label, Object? value) {
    if (value == null || value.toString().trim().isEmpty) return;
    final cleanLabel = label.replaceAll('_', ' ').toUpperCase();
    _line(bytes, '$cleanLabel: $value');
  }

  String _weight(Object? value, Object? unit) {
    if (value == null) return '';
    final parsed = num.tryParse(value.toString());
    final text = parsed == null ? value.toString() : parsed.toStringAsFixed(3);
    return '$text ${unit ?? 'kg'}';
  }

  void _line(List<int> bytes, String value) {
    if (value.trim().isEmpty) return;
    bytes.addAll(latin1.encode(value));
    bytes.add(0x0A);
  }

  void _code128(List<int> bytes, String value) {
    final clean = value.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    if (clean.isEmpty) return;
    bytes.addAll([0x1D, 0x68, 0x50]); // height
    bytes.addAll([0x1D, 0x77, 0x02]); // width
    bytes.addAll([0x1D, 0x48, 0x02]); // text below
    bytes.addAll([0x1D, 0x6B, 0x49, clean.length + 2, 0x7B, 0x42]);
    bytes.addAll(latin1.encode(clean));
    bytes.add(0x0A);
  }
}
