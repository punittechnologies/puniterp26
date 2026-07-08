import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_session.dart';
import '../../../core/database/local_database.dart';
import '../../../services/sync/sync_queue_service.dart';
import '../../dispatch/data/dispatch_repository.dart';
import '../../inventory/data/inventory_repository.dart';
import '../data/report_repository.dart';
import '../../weighing/data/production_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final database = LocalDatabase();
  late final productionRepository = ProductionRepository(database: database);
  late final inventoryRepository = InventoryRepository(database);
  late final dispatchRepository = DispatchRepository(database);
  late SyncQueueService syncQueueService = SyncQueueService(database);
  ReportRepository? reportRepository;
  int index = 0;
  String? message;
  bool downloading = false;

  @override
  void initState() {
    super.initState();
    _loadApi();
  }

  @override
  void dispose() {
    database.close();
    super.dispose();
  }

  Future<void> _loadApi() async {
    final client = await ApiSession.client();
    setState(() {
      reportRepository = ReportRepository(
        database: database,
        apiClient: client,
      );
      syncQueueService = SyncQueueService(database, apiClient: client);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Production',
      'Inventory',
      'Dispatch',
      'Pending Sync',
      'Failed Sync',
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Reports'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          if (compact) {
            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  child: SegmentedButton<int>(
                    segments: [
                      for (final item in tabs.indexed)
                        ButtonSegment(value: item.$1, label: Text(item.$2)),
                    ],
                    selected: {index},
                    onSelectionChanged: (value) =>
                        setState(() => index = value.first),
                  ),
                ),
                Expanded(child: _reportBody(tabs[index])),
              ],
            );
          }

          return Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (value) => setState(() => index = value),
                labelType: NavigationRailLabelType.all,
                destinations: tabs
                    .map(
                      (tab) => NavigationRailDestination(
                        icon: const Icon(Icons.list_alt),
                        label: Text(tab),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _reportBody(tabs[index])),
            ],
          );
        },
      ),
    );
  }

  Widget _reportBody(String tab) {
    if (tab == 'Production') {
      return Column(
        children: [
          _exportBar('production'),
          Expanded(
            child: FutureBuilder(
              future: productionRepository.recent(limit: 200),
              builder: (context, snapshot) => ListView(
                children: (snapshot.data ?? [])
                    .map(
                      (item) => ListTile(
                        title: Text(item.serialNumber),
                        subtitle: Text(item.productId),
                        trailing: Text(item.netWeight.toStringAsFixed(3)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      );
    }
    if (tab == 'Inventory') {
      return Column(
        children: [
          _exportBar('inventory'),
          Expanded(
            child: FutureBuilder(
              future: inventoryRepository.productWise(),
              builder: (context, snapshot) => ListView(
                children: (snapshot.data ?? [])
                    .map(
                      (item) => ListTile(
                        title: Text(item.productId),
                        subtitle: Text(item.variantId ?? '-'),
                        trailing: Text(item.weight.toStringAsFixed(3)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      );
    }
    if (tab == 'Dispatch') {
      return Column(
        children: [
          _exportBar('dispatch'),
          Expanded(
            child: FutureBuilder(
              future: dispatchRepository.history(),
              builder: (context, snapshot) => ListView(
                children: (snapshot.data ?? [])
                    .map(
                      (item) => ListTile(
                        title: Text(item.dispatchNumber),
                        subtitle: Text(item.status),
                        trailing: Text(item.totalWeight.toStringAsFixed(3)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      );
    }
    if (tab == 'Failed Sync') {
      return FutureBuilder(
        future: syncQueueService.failed(),
        builder: (context, snapshot) => ListView(
          children: (snapshot.data ?? [])
              .map(
                (item) => ListTile(
                  title: Text(item.entityType),
                  subtitle: Text(item.operation),
                  trailing: Text('${item.attemptCount} tries'),
                ),
              )
              .toList(),
        ),
      );
    }
    return FutureBuilder(
      future: syncQueueService.pendingCount(),
      builder: (context, snapshot) => Center(
        child: Text(
          '${snapshot.data ?? 0} pending sync entries',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _exportBar(String report) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${report[0].toUpperCase()}${report.substring(1)} exports',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            FilledButton(
              onPressed: downloading ? null : () => _download(report, 'pdf'),
              child: const Text('PDF'),
            ),
            OutlinedButton(
              onPressed: downloading ? null : () => _download(report, 'xlsx'),
              child: const Text('Excel'),
            ),
            OutlinedButton(
              onPressed: downloading ? null : () => _download(report, 'csv'),
              child: const Text('CSV'),
            ),
            if (message != null)
              Text(message!, style: const TextStyle(color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Future<void> _download(String report, String format) async {
    final repository = reportRepository;
    if (repository == null) {
      setState(() => message = 'Connect & Sync on dashboard first.');
      return;
    }
    setState(() {
      downloading = true;
      message = 'Downloading $format...';
    });
    try {
      final file = await repository.downloadReport(report, format);
      setState(() {
        message = file == null
            ? 'Connect & Sync on dashboard first.'
            : 'Saved: ${file.path}';
      });
    } catch (error) {
      setState(() => message = 'Download failed: $error');
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }
}
