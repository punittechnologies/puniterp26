import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_session.dart';
import '../../core/config/app_edition.dart';
import '../../core/database/local_database.dart';
import '../dispatch/data/dispatch_repository.dart';
import '../../services/sync/sync_queue_service.dart';
import '../inventory/data/inventory_repository.dart';
import '../labels/data/label_template_repository.dart';
import '../products/data/product_repository.dart';

class FoundationScreen extends StatefulWidget {
  const FoundationScreen({super.key});

  @override
  State<FoundationScreen> createState() => _FoundationScreenState();
}

class _FoundationScreenState extends State<FoundationScreen> {
  late final LocalDatabase database;
  late final SyncQueueService syncQueue;
  late final InventoryRepository inventory;
  late Future<_DashboardStats> stats;
  final baseUrlController = TextEditingController(
    text: ApiSession.defaultBaseUrl,
  );
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool syncing = false;
  bool connected = false;
  String apiMessage =
      'Connect to Laravel panel to sync products, customers, labels and pending entries.';

  @override
  void initState() {
    super.initState();
    database = LocalDatabase();
    syncQueue = SyncQueueService(database);
    inventory = InventoryRepository(database);
    stats = _loadStats();
    _loadSession();
  }

  @override
  void dispose() {
    baseUrlController.dispose();
    emailController.dispose();
    passwordController.dispose();
    database.close();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final baseUrl = await ApiSession.baseUrl();
    final email = await ApiSession.email();
    final token = await ApiSession.token();
    if (!mounted) return;
    setState(() {
      baseUrlController.text = baseUrl;
      if (email != null) emailController.text = email;
      connected = token != null;
      apiMessage = connected
          ? 'Connected. Ready to sync with Laravel panel.'
          : apiMessage;
    });
    if (token != null) {
      await _syncWithSavedSession();
    }
  }

  Future<_DashboardStats> _loadStats() async {
    final productions = await database
        .select(database.localProductionTransactions)
        .get();
    final dispatches = await database.select(database.localDispatches).get();
    final products = await database.select(database.localProducts).get();
    final inventoryRows = await inventory.productWise();
    final pending = await syncQueue.pendingCount();
    final netWeight = inventoryRows.fold<double>(
      0,
      (total, row) => total + row.weight,
    );
    final netPieces = inventoryRows.fold<double>(
      0,
      (total, row) => total + row.pieces,
    );

    return _DashboardStats(
      productCount: products.length,
      productionCount: productions.length,
      dispatchCount: dispatches.length,
      netWeight: netWeight,
      netPieces: netPieces,
      pendingSync: pending,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      stats = _loadStats();
    });
  }

  Future<void> _logout() async {
    await LabelTemplateRepository(
      database: database,
    ).clearLocalAccountState(allAccounts: true);
    await ApiSession.logout();
    if (!mounted) return;
    setState(() {
      connected = false;
      emailController.clear();
      passwordController.clear();
      apiMessage = 'Logged out. Enter your app user ID and password.';
      stats = _loadStats();
    });
  }

  Future<void> _connectAndSync() async {
    setState(() {
      syncing = true;
      apiMessage = 'Connecting to Laravel panel...';
    });
    try {
      final previousAccount = await ApiSession.email();
      final client = await ApiSession.login(
        baseUrl: baseUrlController.text,
        email: emailController.text,
        password: passwordController.text,
        deviceName:
            '${AppEdition.deviceNamePrefix} ${await ApiSession.deviceId()}',
      );
      final currentAccount = await ApiSession.email();
      if (previousAccount != null &&
          currentAccount != null &&
          previousAccount != currentAccount) {
        await LabelTemplateRepository(
          database: database,
        ).clearLocalAccountState(allAccounts: true);
      }
      await _syncWithClient(client);
      setState(() {
        connected = true;
        apiMessage =
            'Connected. Auto-sync is now running continuously in the background.';
        stats = _loadStats();
      });
    } catch (error) {
      setState(() {
        connected = false;
        apiMessage = _friendlyApiError(error);
      });
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Future<void> _syncWithSavedSession() async {
    final client = await ApiSession.client();
    if (client == null || syncing) return;
    setState(() {
      syncing = true;
      apiMessage = 'Refreshing live configuration from Laravel panel...';
    });
    try {
      await _syncWithClient(client);
      if (!mounted) return;
      setState(() {
        connected = true;
        apiMessage = 'Auto-sync refreshed live products, labels and customers.';
        stats = _loadStats();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        apiMessage = 'Using offline data. ${_friendlyApiError(error)}';
      });
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Future<void> _syncWithClient(ApiClient client) async {
    final deviceId = await ApiSession.deviceId();
    await ProductRepository(
      database: database,
      apiClient: client,
    ).sync(deviceId: deviceId);
    await LabelTemplateRepository(database: database, apiClient: client).sync();
    await CustomerRepository(database, apiClient: client).sync();
    await SyncQueueService(database, apiClient: client).retryPending(passes: 4);
  }

  String _friendlyApiError(Object error) {
    if (error is! DioException) {
      return 'Unable to connect right now. Please retry.';
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;

    if (status == 401 || status == 422) {
      return serverMessage?.isNotEmpty == true
          ? serverMessage!
          : 'Login failed. Check app user ID and password.';
    }
    if (status == 403) {
      return serverMessage?.isNotEmpty == true
          ? serverMessage!
          : 'This app user does not have permission.';
    }
    if (status == 402) {
      return 'Server refused this request. Please check the app user access and retry.';
    }
    if (status == 500 || status == 503) {
      return 'Server is busy. Please retry in a few seconds.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Internet/server connection failed. Please check network and retry.';
    }

    return serverMessage?.isNotEmpty == true
        ? serverMessage!
        : 'Unable to sync. Please retry.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: FutureBuilder<_DashboardStats>(
          future: stats,
          builder: (context, snapshot) {
            final value = snapshot.data ?? _DashboardStats.empty();

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final padding = compact ? 14.0 : 24.0;

                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: compact
                      ? ListView(
                          children: [
                            _Header(
                              onRefresh: _refresh,
                              onLogout: connected ? _logout : null,
                              compact: true,
                            ),
                            const SizedBox(height: 16),
                            _ApiSyncCard(
                              emailController: emailController,
                              passwordController: passwordController,
                              connected: connected,
                              syncing: syncing,
                              message: apiMessage,
                              onSync: _connectAndSync,
                            ),
                            if (connected) ...[
                              const SizedBox(height: 16),
                              _MetricWrap(value: value, compact: true),
                              const SizedBox(height: 16),
                              _ModuleGrid(compact: true),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 360,
                                child: _StatusPanel(
                                  pendingSync: value.pendingSync,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Header(
                                    onRefresh: _refresh,
                                    onLogout: connected ? _logout : null,
                                  ),
                                  const SizedBox(height: 24),
                                  _ApiSyncCard(
                                    emailController: emailController,
                                    passwordController: passwordController,
                                    connected: connected,
                                    syncing: syncing,
                                    message: apiMessage,
                                    onSync: _connectAndSync,
                                  ),
                                  const SizedBox(height: 24),
                                  if (connected)
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            _MetricWrap(value: value),
                                            const SizedBox(height: 24),
                                            const _ModuleGrid(),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    const Expanded(
                                      child: Center(
                                        child: Text(
                                          'Login to start weighing, inventory and dispatch.',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            if (connected)
                              Expanded(
                                flex: 2,
                                child: _StatusPanel(
                                  pendingSync: value.pendingSync,
                                ),
                              ),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, this.onLogout, this.compact = false});

  final VoidCallback onRefresh;
  final VoidCallback? onLogout;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset(
                'assets/brand/punit-logo.png',
                width: compact ? 96 : 132,
                height: compact ? 60 : 82,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppEdition.appTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xFF0B63CE),
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 24 : null,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppEdition.webManagedLabels
                          ? 'Production weighing and printing with the default label managed in the web panel.'
                          : 'Production weighing, offline inventory, dispatch and real Bluetooth scale operation.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        if (onLogout != null) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ],
    );
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.value, this.compact = false});

  final _DashboardStats value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _MetricCard(
          label: 'Products cached',
          value: '${value.productCount}',
          icon: Icons.inventory_2_outlined,
          compact: compact,
        ),
        _MetricCard(
          label: 'Production entries',
          value: '${value.productionCount}',
          icon: Icons.scale_outlined,
          compact: compact,
        ),
        _MetricCard(
          label: 'Net inventory kg',
          value: value.netWeight.toStringAsFixed(3),
          icon: Icons.warehouse_outlined,
          compact: compact,
        ),
        _MetricCard(
          label: 'Net pieces',
          value: value.netPieces.toStringAsFixed(0),
          icon: Icons.tag_outlined,
          compact: compact,
        ),
        _MetricCard(
          label: 'Dispatches',
          value: '${value.dispatchCount}',
          icon: Icons.local_shipping_outlined,
          compact: compact,
        ),
        _MetricCard(
          label: 'Pending sync',
          value: '${value.pendingSync}',
          icon: Icons.cloud_sync_outlined,
          alert: value.pendingSync > 0,
          compact: compact,
        ),
      ],
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: compact ? 1 : 3,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: compact ? 2.35 : 1.7,
      children: const [
        _ModuleTile(
          title: 'Weighing',
          subtitle: 'Live scale, capture, barcode preview',
          route: '/weighing',
          icon: Icons.monitor_weight_outlined,
          primary: true,
        ),
        _ModuleTile(
          title: 'Scale Settings',
          subtitle: 'Pair, connect and diagnose SPP scale',
          route: '/settings',
          icon: Icons.bluetooth_connected,
        ),
        _ModuleTile(
          title: 'Printer Settings',
          subtitle: 'List, connect and test thermal printer',
          route: '/printer-settings',
          icon: Icons.print_outlined,
        ),
        _ModuleTile(
          title: 'Products',
          subtitle: 'Cached product and variant config',
          route: '/products',
          icon: Icons.category_outlined,
        ),
        _ModuleTile(
          title: 'Inventory',
          subtitle: 'Ledger and current balance',
          route: '/inventory',
          icon: Icons.account_balance_outlined,
        ),
        _ModuleTile(
          title: 'Dispatch',
          subtitle: 'Scan, validate and deduct stock',
          route: '/dispatch',
          icon: Icons.document_scanner_outlined,
        ),
        _ModuleTile(
          title: 'Reports',
          subtitle: 'Production, inventory and sync views',
          route: '/reports',
          icon: Icons.bar_chart_outlined,
        ),
      ],
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    required this.productCount,
    required this.productionCount,
    required this.dispatchCount,
    required this.netWeight,
    required this.netPieces,
    required this.pendingSync,
  });

  factory _DashboardStats.empty() => const _DashboardStats(
    productCount: 0,
    productionCount: 0,
    dispatchCount: 0,
    netWeight: 0,
    netPieces: 0,
    pendingSync: 0,
  );

  final int productCount;
  final int productionCount;
  final int dispatchCount;
  final double netWeight;
  final double netPieces;
  final int pendingSync;
}

class _ApiSyncCard extends StatelessWidget {
  const _ApiSyncCard({
    required this.emailController,
    required this.passwordController,
    required this.connected,
    required this.syncing,
    required this.message,
    required this.onSync,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool connected;
  final bool syncing;
  final String message;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: connected ? const Color(0xFF93C5FD) : const Color(0xFFDCE8F7),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final fields = [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'App user ID or email',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton.icon(
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync_outlined),
              label: Text(syncing ? 'Syncing...' : 'Login & Auto-Sync'),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    connected ? Icons.cloud_done : Icons.cloud_off_outlined,
                    color: const Color(0xFF0B63CE),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Punit ERP App Login',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (compact)
                Column(
                  children: fields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: field,
                        ),
                      )
                      .toList(),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fields
                      .map(
                        (field) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: field,
                          ),
                        ),
                      )
                      .toList(),
                ),
              Text(message, style: const TextStyle(color: Color(0xFF475569))),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.alert = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? double.infinity : 210,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFFFBEB) : Colors.white,
        border: Border.all(
          color: alert ? const Color(0xFFF59E0B) : const Color(0xFFDCE8F7),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: alert ? const Color(0xFFB45309) : const Color(0xFF0B63CE),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 22 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.primary = false,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = primary ? const Color(0xFF0B63CE) : Colors.white;
    final textColor = primary ? Colors.white : const Color(0xFF0F172A);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFFDCE8F7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 34,
              color: primary ? Colors.white : const Color(0xFF0B63CE),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primary
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.pendingSync});

  final int pendingSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE8F7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            const _StatusRow(
              label: 'Bluetooth scale',
              value: 'Classic SPP ready',
            ),
            const _StatusRow(label: 'Offline mode', value: 'Enabled'),
            _StatusRow(
              label: 'Cloud sync',
              value: pendingSync == 0 ? 'Clear' : '$pendingSync pending',
              warning: pendingSync > 0,
            ),
            const _StatusRow(
              label: 'Printer',
              value: 'Bluetooth thermal ready',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/weighing'),
              icon: const Icon(Icons.monitor_weight_outlined),
              label: const Text('Start Weighing'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect Scale'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/printer-settings'),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Connect Printer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: warning ? const Color(0xFFD97706) : const Color(0xFF0B63CE),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                Text(value, style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
