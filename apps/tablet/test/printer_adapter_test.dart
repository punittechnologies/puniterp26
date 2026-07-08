import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:punit_tablet/services/devices/bluetooth_thermal_printer_adapter.dart';
import 'package:punit_tablet/services/devices/printer_adapter.dart';
import 'package:punit_tablet/services/devices/thermal_label_renderer.dart';

void main() {
  test(
    'thermal renderer includes label values and esc pos barcode command',
    () {
      final bytes = const ThermalLabelRenderer().render(
        const PrintJob(
          jobId: 'job-1',
          template: {},
          data: {
            'company_name': 'Punit',
            'product_name': 'Wire',
            'serial_number': 'SER-1',
            'barcode_value': 'BAR123',
            'gross_weight': 12.5,
            'tare_weight': 0.5,
            'net_weight': 12,
            'unit': 'kg',
            'dynamic_values': {'SIZE': '16'},
          },
        ),
      );
      final printable = latin1.decode(bytes, allowInvalid: true);

      expect(printable, contains('Wire'));
      expect(printable, contains('BAR123'));
      expect(printable, contains('NET: 12.000 kg'));
      expect(bytes, containsAllInOrder([0x1D, 0x6B, 0x49]));
    },
  );

  test('TSPL template prints normalized dynamic product detail fields', () {
    final tspl = BluetoothThermalPrinterAdapter().debugTspl(
      const PrintJob(
        jobId: 'job-2',
        template: {
          'widthMm': 75,
          'heightMm': 75,
          'elements': [
            {
              'key': 'company',
              'type': 'static_text',
              'bindingKey': 'PUNIT ERP',
              'x': 5,
              'y': 4,
              'width': 65,
              'height': 6,
              'layerOrder': 1,
              'style': {'fontSize': 10, 'align': 'center'},
            },
            {
              'key': 'size',
              'type': 'binding_text',
              'bindingKey': 'dynamic.product_variant.size',
              'prefix': 'Size: ',
              'x': 5,
              'y': 14,
              'width': 65,
              'height': 6,
              'layerOrder': 2,
              'style': {'fontSize': 9, 'align': 'left'},
            },
            {
              'key': 'barcode',
              'type': 'barcode',
              'bindingKey': 'barcode.value',
              'x': 5,
              'y': 52,
              'width': 65,
              'height': 17,
              'layerOrder': 3,
            },
          ],
        },
        data: {
          'product_name': 'Wire',
          'barcode_value': 'UNIQUE-BARCODE-123456789',
          'dynamic_values': {'size': '16'},
        },
      ),
    );

    expect(tspl, contains('PUNIT ERP'));
    expect(tspl, contains('Size: 16'));
    expect(tspl, contains(',"128",'));
    expect(tspl, contains(',0,0,2,2,'));
  });
}
