import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:punit_tablet/features/weighing/data/label_serial_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formats optional prefix and preserves configured digits', () {
    final settings = LabelSerialSettings(
      prefix: 'SPM-',
      nextNumber: BigInt.from(3000),
      digits: 6,
      increment: BigInt.one,
    );

    expect(settings.preview, 'SPM-003000');
  });

  test('claiming a serial advances the account-scoped sequence', () async {
    SharedPreferences.setMockInitialValues({
      'label_serial_signed-out_prefix': '',
      'label_serial_signed-out_next_number': '3000',
      'label_serial_signed-out_digits': 0,
      'label_serial_signed-out_increment': '1',
    });
    const service = LabelSerialService();

    expect(await service.claimNext(), '3000');
    expect((await service.load()).preview, '3001');
  });
}
