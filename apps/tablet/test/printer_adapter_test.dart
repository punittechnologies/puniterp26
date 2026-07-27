import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
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
    expect(tspl, contains('BARCODE 140,416,"128",72,0,0,1,1,'));
  });

  test('TSPL uses real Font 3 metrics when centering bold text', () {
    final tspl = BluetoothThermalPrinterAdapter().debugTspl(
      const PrintJob(
        jobId: 'job-centered-font',
        template: {
          'widthMm': 75,
          'heightMm': 75,
          'elements': [
            {
              'type': 'binding_text',
              'bindingKey': 'company.name',
              'x': 5,
              'y': 4,
              'width': 65,
              'height': 6,
              'style': {
                'fontSize': 10,
                'fontWeight': 'bold',
                'align': 'center',
              },
            },
            {'type': 'barcode', 'x': 5, 'y': 52, 'width': 65, 'height': 17},
          ],
        },
        data: {'company_name': 'PUNIT ERP', 'barcode_value': 'PHKS06B99XB'},
      ),
    );

    // 65 mm = 520 dots. Font 3 is 16 dots wide, so nine characters
    // occupy 144 dots and start at 40 + ((520 - 144) / 2) = 228.
    expect(tspl, contains('TEXT 228,32,"3",0,1,1,"PUNIT ERP"'));
    expect(tspl, contains('BARCODE 124,416,"128",72,0,0,2,2,'));
    expect(tspl, contains('TEXT 256,560,"1",0,1,1,"PHKS06B99XB"'));
  });

  test('TSPL keeps prefix value and suffix in one atomic text command', () {
    final tspl = BluetoothThermalPrinterAdapter().debugTspl(
      const PrintJob(
        jobId: 'job-affix-overlap',
        template: {
          'widthMm': 75,
          'heightMm': 75,
          'elements': [
            {
              'type': 'binding_text',
              'bindingKey': 'product.name',
              'prefix': 'PART: ',
              'suffix': ' ±',
              'x': 5,
              'y': 20,
              'width': 65,
              'height': 8,
              'style': {
                'fontSize': 12,
                'prefixFontSize': 7,
                'suffixFontSize': 18,
                'fontWeight': '800',
                'align': 'left',
              },
            },
            {'type': 'barcode', 'x': 5, 'y': 52, 'width': 65, 'height': 17},
          ],
        },
        data: {'product_name': 'DM19C3', 'barcode_value': 'PHK123'},
      ),
    );

    expect(tspl, contains('TEXT 40,160,"3",0,1,1,"PART: DM19C3 +/-"'));
    expect(tspl, isNot(contains('"PART: "')));
    expect(tspl, isNot(contains('"DM19C3"')));
  });

  test('Web Label emits a firmware-safe QR bitmap without changing barcode', () {
    final adapter = BluetoothThermalPrinterAdapter(qrPrintingEnabled: true);
    const job = PrintJob(
      jobId: 'job-secure-qr',
      template: {
        'widthMm': 75,
        'heightMm': 75,
        'elements': [
          {
            'type': 'qr',
            'bindingKey': 'qr.value',
            'x': 48,
            'y': 4,
            'width': 22,
            'height': 22,
            'rotation': 0,
          },
          {'type': 'barcode', 'x': 5, 'y': 52, 'width': 65, 'height': 17},
        ],
      },
      data: {
        'qr_value':
            'https://erp.puniterp.com/verify/AbCdEfGhIjKlMnOpQrStUvWxYz1234567890ABCDEFGHIJ',
        'barcode_value': 'PHK123',
      },
    );
    final tspl = adapter.debugTspl(job);
    final bytes = adapter.debugTsplBytes(job);

    expect(tspl, contains('BITMAP '));
    expect(tspl, contains('bitmap bytes>'));
    expect(tspl, isNot(contains('QRCODE ')));
    expect(tspl, contains('BARCODE '));
    expect(bytes, containsAllInOrder(ascii.encode('BITMAP ')));
    expect(
      latin1.decode(bytes, allowInvalid: true),
      isNot(contains('https://erp.puniterp.com/verify/')),
    );
  });

  test('TVS native path leaves QR and final print to the vendor SDK', () {
    final adapter = BluetoothThermalPrinterAdapter(qrPrintingEnabled: true);
    const job = PrintJob(
      jobId: 'job-native-secure-qr',
      template: {
        'widthMm': 75,
        'heightMm': 75,
        'elements': [
          {
            'type': 'qr',
            'bindingKey': 'qr.value',
            'x': 50,
            'y': 55,
            'width': 17.5,
            'height': 17.5,
          },
          {'type': 'barcode', 'x': 5, 'y': 45, 'width': 40, 'height': 17},
        ],
      },
      data: {
        'qr_value':
            'https://erp.puniterp.com/verify/AbCdEfGhIjKlMnOpQrStUvWxYz1234567890ABCDEFGHIJ',
        'barcode_value': 'PHK123',
      },
    );

    final nativeTspl = latin1.decode(
      adapter.debugNativeTsplBytes(job),
      allowInvalid: true,
    );
    final qrSpec = adapter.debugNativeQrSpec(job);

    expect(nativeTspl, contains('BARCODE '));
    expect(nativeTspl, isNot(contains('BITMAP ')));
    expect(nativeTspl, isNot(contains('QRCODE ')));
    expect(nativeTspl, isNot(contains('PRINT 1,1')));
    expect(qrSpec, isNotNull);
    expect(qrSpec!['value'], contains('/verify/'));
    expect(qrSpec['cellWidth'], inInclusiveRange(2, 8));
  });

  test('Classic edition skips QR elements and preserves barcode output', () {
    final tspl = BluetoothThermalPrinterAdapter(qrPrintingEnabled: false)
        .debugTspl(
          const PrintJob(
            jobId: 'job-classic-no-qr',
            template: {
              'widthMm': 75,
              'heightMm': 75,
              'elements': [
                {
                  'type': 'qr',
                  'bindingKey': 'qr.value',
                  'x': 48,
                  'y': 4,
                  'width': 22,
                  'height': 22,
                },
                {'type': 'barcode', 'x': 5, 'y': 52, 'width': 65, 'height': 17},
              ],
            },
            data: {
              'qr_value': 'https://erp.puniterp.com/verify/token',
              'barcode_value': 'PHK123',
            },
          ),
        );

    expect(tspl, isNot(contains('QRCODE ')));
    expect(tspl, contains('BARCODE '));
  });

  test('TSPL image element is emitted as raw bitmap bytes', () {
    final image = img.Image(width: 8, height: 8);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    for (var index = 0; index < 8; index++) {
      image.setPixel(index, index, img.ColorRgb8(0, 0, 0));
    }

    final bytes = BluetoothThermalPrinterAdapter().debugTsplBytes(
      PrintJob(
        jobId: 'job-image',
        template: {
          'widthMm': 75,
          'heightMm': 75,
          'elements': [
            {
              'key': 'logo',
              'type': 'image',
              'x': 2,
              'y': 2,
              'width': 1,
              'height': 1,
              'layerOrder': 1,
              'imageBase64': base64Encode(img.encodePng(image)),
            },
            {
              'key': 'barcode',
              'type': 'barcode',
              'x': 5,
              'y': 52,
              'width': 65,
              'height': 17,
              'layerOrder': 2,
            },
          ],
        },
        data: const {'barcode_value': 'PHK123'},
      ),
    );

    final marker = ascii.encode('BITMAP 16,16,1,8,0,');
    final start = _indexOfBytes(bytes, marker);
    expect(start, isNonNegative);
    final bitmapStart = start + marker.length;
    expect(bytes.sublist(bitmapStart, bitmapStart + 8), isNot(contains(0x30)));
    expect(bytes.sublist(bitmapStart, bitmapStart + 8), contains(0x80));
  });
}

int _indexOfBytes(List<int> haystack, List<int> needle) {
  for (var index = 0; index <= haystack.length - needle.length; index++) {
    var found = true;
    for (var offset = 0; offset < needle.length; offset++) {
      if (haystack[index + offset] != needle[offset]) {
        found = false;
        break;
      }
    }
    if (found) return index;
  }
  return -1;
}
