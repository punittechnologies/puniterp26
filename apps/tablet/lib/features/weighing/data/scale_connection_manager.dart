import 'dart:async';

import '../domain/scale_models.dart';

class ScaleConnectionManager {
  ScaleConnectionManager(this.adapter);

  final ScaleAdapter adapter;
  Timer? _retryTimer;
  int _attempts = 0;

  ScaleConnectionStatus get status => adapter.status;

  Future<void> connectWithRetry({
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    if (adapter.status == ScaleConnectionStatus.connected ||
        adapter.status == ScaleConnectionStatus.connecting) {
      return;
    }
    _attempts = 0;
    await _connect(maxAttempts, delay);
  }

  Future<void> disconnect() async {
    _retryTimer?.cancel();
    await adapter.disconnect();
  }

  Future<void> reconnect() async {
    await disconnect();
    await connectWithRetry();
  }

  Future<void> _connect(int maxAttempts, Duration delay) async {
    try {
      _attempts += 1;
      await adapter.connect();
    } catch (_) {
      if (_attempts >= maxAttempts) return;
      _retryTimer = Timer(delay, () => _connect(maxAttempts, delay));
    }
  }
}
