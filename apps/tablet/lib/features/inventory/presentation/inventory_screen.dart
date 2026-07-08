import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_session.dart';
import '../../../core/database/local_database.dart';
import '../data/inventory_repository.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final database = LocalDatabase();
  late InventoryRepository repository = InventoryRepository(database);
  List<InventorySummary> summaries = [];
  List<InventoryDetailSummary> detailSummaries = [];
  List<LocalInventoryLedgerData> ledger = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = await ApiSession.client();
    repository = InventoryRepository(database, apiClient: client);
    final nextSummaries = await repository.productWise();
    final nextDetailSummaries = await repository.detailWise();
    final nextLedger = await repository.ledger();
    setState(() {
      summaries = nextSummaries;
      detailSummaries = nextDetailSummaries;
      ledger = nextLedger;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalWeight = summaries.fold(0.0, (sum, item) => sum + item.weight);
    final totalPieces = summaries.fold(0.0, (sum, item) => sum + item.pieces);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Inventory'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final summaryPanel = _summaryPanel(totalWeight, totalPieces);
          final detailPanel = _detailPanel();
          final ledgerPanel = _ledgerPanel();

          if (compact) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                SizedBox(height: 390, child: summaryPanel),
                const SizedBox(height: 12),
                SizedBox(height: 460, child: detailPanel),
                const SizedBox(height: 12),
                SizedBox(height: 520, child: ledgerPanel),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 320, child: summaryPanel),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: detailPanel),
                      const SizedBox(height: 16),
                      Expanded(child: ledgerPanel),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Detail Inventory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (detailSummaries.isEmpty)
              const Expanded(
                child: Center(child: Text('No product-detail stock split yet')),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: detailSummaries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = detailSummaries[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFF),
                        border: Border.all(color: const Color(0xFFD6E8FF)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.weight.toStringAsFixed(3)} kg',
                                style: const TextStyle(
                                  color: Color(0xFF0B57D0),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: item.details.isEmpty
                                ? const [Chip(label: Text('Base product'))]
                                : item.details.entries
                                      .map(
                                        (entry) => Chip(
                                          label: Text(
                                            '${entry.key}: ${entry.value}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.entries} entries · ${item.pieces.toStringAsFixed(0)} pcs',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryPanel(double totalWeight, double totalPieces) {
    return Column(
      children: [
        _tile('Total KG', totalWeight.toStringAsFixed(3)),
        _tile('Total PCS', totalPieces.toStringAsFixed(0)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: summaries
                .map(
                  (item) => ListTile(
                    title: Text(item.productName ?? item.productId),
                    subtitle: Text(
                      item.variantName ?? item.variantId ?? 'All details',
                    ),
                    trailing: Text(item.weight.toStringAsFixed(3)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _ledgerPanel() {
    return Card(
      child: ListView(
        children: ledger
            .map(
              (item) => ListTile(
                title: Text(
                  '${item.transactionType} ${item.weightQuantity.toStringAsFixed(3)} kg',
                ),
                subtitle: Text(
                  '${item.productId} / ${item.barcodeValue ?? '-'}',
                ),
                trailing: Text(
                  item.occurredAt.toIso8601String().substring(0, 16),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _tile(String label, String value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}
