import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';
import '../../../core/database/local_database.dart';

class CustomerRepository {
  const CustomerRepository(this.database, {this.apiClient});
  final LocalDatabase database;
  final ApiClient? apiClient;

  Future<List<LocalCustomer>> cachedCustomers() {
    return (database.select(
      database.localCustomers,
    )..where((row) => row.isActive.equals(true))).get();
  }

  Future<void> activatePayload(Map<String, dynamic> payload) async {
    await database.transaction(() async {
      await database.delete(database.localCustomers).go();
      for (final raw in (payload['customers'] as List<dynamic>? ?? const [])) {
        final customer = raw as Map<String, dynamic>;
        await database
            .into(database.localCustomers)
            .insert(
              LocalCustomersCompanion.insert(
                id: customer['id'] as String,
                name: customer['name'] as String,
                code: Value(customer['code'] as String?),
                payloadJson: jsonEncode(customer),
                isActive: Value(customer['is_active'] as bool? ?? true),
              ),
            );
      }
    });
  }

  Future<void> sync() async {
    final client = apiClient;
    if (client == null) return;
    final response = await client.get('/customers', query: {'per_page': 500});
    final payload = response.data as Map<String, dynamic>;
    await activatePayload({'customers': payload['data'] ?? const []});
  }
}

class BarcodeScannerService {
  String normalize(String input) => input
      .trim()
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F\s]+'), '')
      .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '')
      .toUpperCase();
}

class DispatchBarcodeException implements Exception {
  const DispatchBarcodeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DispatchRepository {
  const DispatchRepository(this.database, {this.apiClient});
  final LocalDatabase database;
  final ApiClient? apiClient;

  Future<void> syncHistory() async {
    final client = apiClient;
    if (client == null) return;

    final response = await client.get('/sync/dispatches', query: {'limit': 50});
    final payload = response.data as Map<String, dynamic>;
    final rows = payload['data'] as List<dynamic>? ?? const [];
    final accountScope = await ApiSession.accountScope();
    await database.transaction(() async {
      for (final raw in rows) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['id']?.toString();
        final number = raw['dispatch_number']?.toString();
        final customerId = raw['customer_id']?.toString();
        if (id == null ||
            id.isEmpty ||
            number == null ||
            number.isEmpty ||
            customerId == null ||
            customerId.isEmpty) {
          continue;
        }
        await database
            .into(database.localDispatches)
            .insertOnConflictUpdate(
              LocalDispatchesCompanion.insert(
                id: id,
                accountScope: Value(accountScope),
                dispatchNumber: number,
                customerId: customerId,
                customerSnapshotJson: jsonEncode(
                  raw['customer_snapshot'] ?? const {},
                ),
                status: Value(raw['status']?.toString() ?? 'confirmed'),
                totalWeight: Value(_asDouble(raw['total_weight'])),
                totalPieces: Value(_asNullableDouble(raw['total_pieces'])),
                syncStatus: const Value('synced'),
                idempotencyKey: 'server_$id',
                createdAt:
                    DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
                    DateTime.now(),
                confirmedAt: Value(
                  DateTime.tryParse(raw['confirmed_at']?.toString() ?? ''),
                ),
              ),
            );
      }
    });
  }

  Future<LocalProductionTransaction?> findAvailableBarcode(
    String barcode,
  ) async {
    final accountScope = await ApiSession.accountScope();
    final serverItem = await _findServerBarcode(barcode);
    if (serverItem != null) return serverItem;

    final production =
        await (database.select(database.localProductionTransactions)..where(
              (row) =>
                  (row.barcodeValue.equals(barcode) |
                      row.labelSerialNumber.equals(barcode) |
                      (row.labelSerialNumber.isNull() &
                          row.serialNumber.equals(barcode))) &
                  row.accountScope.equals(accountScope),
            ))
            .getSingleOrNull();
    if (production == null) return null;
    final dispatched =
        await (database.select(database.localDispatchItems)..where(
              (row) =>
                  row.barcodeValue.equals(barcode) &
                  row.accountScope.equals(accountScope),
            ))
            .getSingleOrNull();
    return dispatched == null ? production : null;
  }

  Future<LocalProductionTransaction?> _findServerBarcode(String barcode) async {
    final client = apiClient;
    if (client == null) return null;

    try {
      final response = await client.get(
        '/dispatch/barcodes/${Uri.encodeComponent(barcode)}',
      );
      final payload = response.data as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>? ?? const {};
      final capturedAt = DateTime.tryParse(
        data['captured_at']?.toString() ?? '',
      );

      return LocalProductionTransaction(
        id: data['id']?.toString() ?? 'server_$barcode',
        accountScope: await ApiSession.accountScope(),
        serialNumber: data['serial_number']?.toString() ?? barcode,
        labelSerialNumber: data['label_serial_number']?.toString(),
        barcodeValue: data['barcode_value']?.toString() ?? barcode,
        productId: data['product_id']?.toString() ?? '',
        variantId: data['variant_id']?.toString(),
        inwardSessionId: data['inward_session_id']?.toString(),
        productSnapshotJson: jsonEncode(data['product_snapshot'] ?? const {}),
        dynamicValuesJson: jsonEncode(data['dynamic_values'] ?? const {}),
        grossWeight: _asDouble(data['gross_weight']),
        tareWeight: _asDouble(data['tare_weight']),
        netWeight: _asDouble(data['net_weight']),
        pieceQuantity: _asNullableDouble(data['piece_quantity']),
        unit: data['unit']?.toString() ?? 'kg',
        status: 'server_available',
        syncStatus: 'synced',
        idempotencyKey: 'server_${data['id'] ?? barcode}',
        rawReadingJson: '{}',
        capturedAt: capturedAt ?? DateTime.now(),
      );
    } on DioException catch (error) {
      if (error.response != null) {
        throw DispatchBarcodeException(_apiErrorMessage(error));
      }

      return null;
    }
  }

  String _apiErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
      final message = data['message'];
      if (message != null) return message.toString();
    }

    return 'Barcode is not available for dispatch.';
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _asNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<String> confirmDispatch({
    required LocalCustomer customer,
    required List<LocalProductionTransaction> items,
  }) async {
    final accountScope = await ApiSession.accountScope();
    final now = DateTime.now();
    final id = 'disp_${now.microsecondsSinceEpoch}';
    final idempotency = 'idem_$id';
    final number =
        'DSP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.microsecondsSinceEpoch}';
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.netWeight);
    final totalPieces = items.fold(
      0.0,
      (sum, item) => sum + (item.pieceQuantity ?? 0),
    );

    await database.transaction(() async {
      await database
          .into(database.localDispatches)
          .insert(
            LocalDispatchesCompanion.insert(
              id: id,
              accountScope: Value(accountScope),
              dispatchNumber: number,
              customerId: customer.id,
              customerSnapshotJson: customer.payloadJson,
              status: const Value('confirmed'),
              totalWeight: Value(totalWeight),
              totalPieces: Value(totalPieces),
              idempotencyKey: idempotency,
              createdAt: now,
              confirmedAt: Value(now),
            ),
          );

      for (final item in items) {
        await database
            .into(database.localDispatchItems)
            .insert(
              LocalDispatchItemsCompanion.insert(
                id: 'di_${item.id}',
                accountScope: Value(accountScope),
                dispatchId: id,
                productionTransactionId: item.id,
                barcodeValue: item.barcodeValue,
                weightQuantity: item.netWeight,
                pieceQuantity: Value(item.pieceQuantity),
              ),
            );
        await database
            .into(database.localInventoryLedger)
            .insert(
              LocalInventoryLedgerCompanion.insert(
                id: 'inv_disp_${item.id}',
                accountScope: Value(accountScope),
                productId: item.productId,
                variantId: Value(item.variantId),
                serialNumber: Value(item.serialNumber),
                barcodeValue: Value(item.barcodeValue),
                transactionType: 'dispatch_deduction',
                weightQuantity: item.netWeight,
                pieceQuantity: Value(item.pieceQuantity),
                referenceType: 'dispatch',
                referenceId: id,
                occurredAt: now,
              ),
            );
      }

      await database
          .into(database.localSyncQueue)
          .insert(
            LocalSyncQueueCompanion.insert(
              id: 'sync_$id',
              accountScope: Value(accountScope),
              entityType: 'dispatch',
              operation: 'create',
              idempotencyKey: idempotency,
              payloadJson: jsonEncode({
                'id': id,
                'dispatch_number': number,
                'customer_id': customer.id,
                'barcodes': items.map((item) => item.barcodeValue).toList(),
                'confirmed_at': now.toIso8601String(),
              }),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    return id;
  }

  Future<LocalDispatche?> findDispatch(String id) async {
    final accountScope = await ApiSession.accountScope();
    return (database.select(database.localDispatches)..where(
          (row) => row.id.equals(id) & row.accountScope.equals(accountScope),
        ))
        .getSingleOrNull();
  }

  Future<List<LocalDispatche>> history() async {
    final accountScope = await ApiSession.accountScope();
    return (database.select(database.localDispatches)
          ..where((row) => row.accountScope.equals(accountScope))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }
}
