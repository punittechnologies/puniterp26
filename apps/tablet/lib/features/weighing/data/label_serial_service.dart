import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';

class LabelSerialSettings {
  const LabelSerialSettings({
    required this.prefix,
    required this.nextNumber,
    required this.digits,
    required this.increment,
  });

  final String prefix;
  final BigInt nextNumber;
  final int digits;
  final BigInt increment;

  String format(BigInt number) {
    final raw = number.toString();
    return '$prefix${digits > 0 ? raw.padLeft(digits, '0') : raw}';
  }

  String get preview => format(nextNumber);

  Map<String, dynamic> toJson() => {
    'prefix': prefix,
    'next_number': nextNumber.toString(),
    'digits': digits,
    'increment': increment.toString(),
  };
}

class LabelSerialService {
  const LabelSerialService();

  Future<String> _key(String field) async =>
      'label_serial_${await ApiSession.accountScope()}_$field';

  Future<LabelSerialSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = prefs.getString(await _key('prefix')) ?? '';
    final next =
        BigInt.tryParse(prefs.getString(await _key('next_number')) ?? '') ??
        BigInt.one;
    final digits = prefs.getInt(await _key('digits')) ?? 0;
    final increment =
        BigInt.tryParse(prefs.getString(await _key('increment')) ?? '') ??
        BigInt.one;
    return LabelSerialSettings(
      prefix: prefix,
      nextNumber: next,
      digits: digits,
      increment: increment,
    );
  }

  Future<void> save({
    required LabelSerialSettings settings,
    required String password,
    required ApiClient apiClient,
  }) async {
    final old = await load();
    await apiClient.post(
      '/auth/confirm-password',
      data: {
        'password': password,
        'action': 'label_serial.updated',
        'old_values': old.toJson(),
        'new_values': settings.toJson(),
      },
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _key('prefix'), settings.prefix);
    await prefs.setString(
      await _key('next_number'),
      settings.nextNumber.toString(),
    );
    await prefs.setInt(await _key('digits'), settings.digits);
    await prefs.setString(
      await _key('increment'),
      settings.increment.toString(),
    );
  }

  Future<String> claimNext() async {
    final settings = await load();
    final serial = settings.preview;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      await _key('next_number'),
      (settings.nextNumber + settings.increment).toString(),
    );
    return serial;
  }
}
