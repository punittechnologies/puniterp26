import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_session.dart';
import 'core/database/local_database.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/dispatch/data/dispatch_repository.dart';
import 'features/labels/data/label_template_repository.dart';
import 'features/products/data/product_repository.dart';
import 'services/sync/sync_queue_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PunitTabletApp()));
}

class PunitTabletApp extends ConsumerStatefulWidget {
  const PunitTabletApp({super.key});

  @override
  ConsumerState<PunitTabletApp> createState() => _PunitTabletAppState();
}

class _PunitTabletAppState extends ConsumerState<PunitTabletApp>
    with WidgetsBindingObserver {
  Timer? syncTimer;
  bool _syncInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncNow();
    syncTimer = Timer.periodic(const Duration(seconds: 3), (_) => _syncNow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNow();
    }
  }

  Future<void> _syncNow() async {
    if (_syncInProgress) return;
    final client = await ApiSession.client();
    if (client == null) return;
    _syncInProgress = true;
    final database = LocalDatabase();
    try {
      final deviceId = await ApiSession.deviceId();
      await ProductRepository(
        database: database,
        apiClient: client,
      ).sync(deviceId: deviceId);
      await LabelTemplateRepository(
        database: database,
        apiClient: client,
      ).sync();
      await CustomerRepository(database, apiClient: client).sync();
      await DispatchRepository(database, apiClient: client).syncHistory();
      await SyncQueueService(
        database,
        apiClient: client,
      ).retryPending(passes: 4);
    } catch (_) {
      // Background sync must never interrupt weighing/dispatch workflows.
    } finally {
      _syncInProgress = false;
      await database.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Punit ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
