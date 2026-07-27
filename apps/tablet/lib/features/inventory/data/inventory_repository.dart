import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';
import '../../../core/database/local_database.dart';

class InventorySummary {
  const InventorySummary({
    required this.productId,
    this.variantId,
    this.productName,
    this.variantName,
    required this.weight,
    required this.pieces,
  });
  final String productId;
  final String? variantId;
  final String? productName;
  final String? variantName;
  final double weight;
  final double pieces;
}

class InventoryDetailSummary {
  const InventoryDetailSummary({
    required this.productId,
    required this.productName,
    required this.details,
    required this.weight,
    required this.pieces,
    required this.entries,
  });

  final String productId;
  final String productName;
  final Map<String, String> details;
  final double weight;
  final double pieces;
  final int entries;
}

class InventoryRepository {
  const InventoryRepository(this.database, {this.apiClient});

  final LocalDatabase database;
  final ApiClient? apiClient;

  Future<List<LocalInventoryLedgerData>> ledger({int limit = 200}) async {
    final accountScope = await ApiSession.accountScope();
    return (database.select(database.localInventoryLedger)
          ..where((row) => row.accountScope.equals(accountScope))
          ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)])
          ..limit(limit))
        .get();
  }

  Future<List<InventorySummary>> productWise({bool preferServer = true}) async {
    if (preferServer && apiClient != null) {
      try {
        return await _serverProductWise();
      } catch (_) {
        // Keep inventory usable from local data when internet/API is unavailable.
      }
    }

    return _localProductWise();
  }

  Future<List<InventorySummary>> _serverProductWise() async {
    final response = await apiClient!.get('/inventory/summary');
    final payload = response.data as Map<String, dynamic>;
    final rows = payload['data'] as List<dynamic>? ?? const [];
    final productNames = await _productNames();
    final variantNames = await _variantNames();

    return rows.map((row) {
      final json = row as Map<String, dynamic>;
      final productId = json['product_id']?.toString() ?? '';
      final variantId = json['variant_id']?.toString();
      return InventorySummary(
        productId: productId,
        variantId: variantId == null || variantId.isEmpty ? null : variantId,
        productName: productNames[productId],
        variantName: variantId == null ? null : variantNames[variantId],
        weight: _asDouble(json['closing_weight']),
        pieces: _asDouble(json['closing_pieces']),
      );
    }).toList();
  }

  Future<List<InventoryDetailSummary>> detailWise() async {
    if (apiClient != null) {
      try {
        final response = await apiClient!.get('/inventory/summary');
        final payload = response.data as Map<String, dynamic>;
        final rows = payload['detail_cards'] as List<dynamic>? ?? const [];
        return rows.map((row) {
          final json = row as Map<String, dynamic>;
          final details = <String, String>{};
          final rawDetails = json['details'];
          if (rawDetails is Map) {
            for (final entry in rawDetails.entries) {
              details[entry.key.toString()] = entry.value.toString();
            }
          }
          return InventoryDetailSummary(
            productId: json['product_id']?.toString() ?? '',
            productName: json['product_name']?.toString() ?? 'Product',
            details: details,
            weight: _asDouble(json['weight']),
            pieces: _asDouble(json['pieces']),
            entries: int.tryParse(json['entries']?.toString() ?? '') ?? 0,
          );
        }).toList();
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  Future<List<InventorySummary>> _localProductWise() async {
    final accountScope = await ApiSession.accountScope();
    final rows = await (database.select(
      database.localInventoryLedger,
    )..where((row) => row.accountScope.equals(accountScope))).get();
    final productNames = await _productNames();
    final variantNames = await _variantNames();
    final grouped = <String, InventorySummary>{};
    for (final row in rows) {
      final sign = row.transactionType.contains('dispatch') ? -1.0 : 1.0;
      final key = '${row.productId}|${row.variantId ?? ''}';
      final current =
          grouped[key] ??
          InventorySummary(
            productId: row.productId,
            variantId: row.variantId,
            productName: productNames[row.productId],
            variantName: row.variantId == null
                ? null
                : variantNames[row.variantId],
            weight: 0,
            pieces: 0,
          );
      grouped[key] = InventorySummary(
        productId: row.productId,
        variantId: row.variantId,
        productName: current.productName,
        variantName: current.variantName,
        weight: current.weight + (row.weightQuantity * sign),
        pieces: current.pieces + ((row.pieceQuantity ?? 0) * sign),
      );
    }
    return grouped.values.toList();
  }

  Future<Map<String, String>> _productNames() async {
    final rows = await database.select(database.localProducts).get();
    return {for (final row in rows) row.id: row.name};
  }

  Future<Map<String, String>> _variantNames() async {
    final rows = await database.select(database.localProductVariants).get();
    return {for (final row in rows) row.id: row.name};
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<double> productWeight(String productId, {String? variantId}) async {
    final summaries = await productWise();
    var total = 0.0;
    for (final item in summaries.where(
      (item) =>
          item.productId == productId &&
          (variantId == null || item.variantId == variantId),
    )) {
      total += item.weight;
    }
    return total;
  }
}
