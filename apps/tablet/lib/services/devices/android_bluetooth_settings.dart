import 'package:flutter/services.dart';

class AndroidBluetoothSettings {
  const AndroidBluetoothSettings();

  static const _channel = MethodChannel('punit.erp/bluetooth');

  Future<void> open() async {
    try {
      await _channel.invokeMethod<bool>('openBluetoothSettings');
    } on MissingPluginException {
      return;
    }
  }
}
