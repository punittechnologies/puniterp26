import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/database/local_database.dart';
import '../../products/domain/product_models.dart';
import '../domain/scale_models.dart';
import '../domain/weighing_logic.dart';

class ProductionRepository {
  const ProductionRepository({required this.database, this.apiClient});

  final LocalDatabase database;
  final ApiClient? apiClient;

  Future<String> capture({
    required ProductConfig product,
    ProductVariantConfig? variant,
    required WeightComputation computation,
    required ScaleReading reading,
    Map<String, dynamic> dynamicValues = const {},
    LocalInwardSession? inwardSession,
  }) async {
    final now = DateTime.now();
    final id = 'prod_${now.microsecondsSinceEpoch}';
    final short = now.microsecondsSinceEpoch.toRadixString(36).toUpperCase();
    final productPart = product.productCode
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase()
        .padRight(3, 'X')
        .substring(0, 3);
    final serial = '$productPart-${_date(now).substring(2)}-$short';
    final barcode = 'P$short';
    final idempotency = 'idem_$id';
    final snapshot = {'product': product.raw, 'variant': variant?.raw};

    await database.transaction(() async {
      await database
          .into(database.localProductionTransactions)
          .insert(
            LocalProductionTransactionsCompanion.insert(
              id: id,
              serialNumber: serial,
              barcodeValue: barcode,
              productId: product.id,
              variantId: Value(variant?.id),
              inwardSessionId: Value(inwardSession?.id),
              productSnapshotJson: jsonEncode(snapshot),
              dynamicValuesJson: Value(jsonEncode(dynamicValues)),
              grossWeight: computation.gross,
              tareWeight: computation.tare,
              netWeight: computation.net,
              pieceQuantity: Value(
                double.tryParse(computation.roundedPieces ?? ''),
              ),
              unit: Value(computation.unit),
              idempotencyKey: idempotency,
              rawReadingJson: jsonEncode(reading.toJson()),
              capturedAt: now,
            ),
          );
      await database
          .into(database.localInventoryLedger)
          .insert(
            LocalInventoryLedgerCompanion.insert(
              id: 'inv_${now.microsecondsSinceEpoch}',
              productId: product.id,
              variantId: Value(variant?.id),
              serialNumber: Value(serial),
              barcodeValue: Value(barcode),
              transactionType: 'production_addition',
              weightQuantity: computation.net,
              pieceQuantity: Value(
                double.tryParse(computation.roundedPieces ?? ''),
              ),
              referenceType: 'production',
              referenceId: id,
              occurredAt: now,
            ),
          );
      await database
          .into(database.localSyncQueue)
          .insert(
            LocalSyncQueueCompanion.insert(
              id: 'sync_$id',
              entityType: 'production_transaction',
              operation: 'create',
              idempotencyKey: idempotency,
              payloadJson: jsonEncode({
                'id': id,
                'serial_number': serial,
                'barcode_value': barcode,
                'product_id': product.id,
                'variant_id': variant?.id,
                'inward_session_id': inwardSession?.id,
                'inward_session_number': inwardSession?.sessionNumber,
                'inward_session_status': inwardSession?.status,
                'inward_session_started_at': inwardSession?.startedAt
                    .toIso8601String(),
                'inward_session_ended_at': inwardSession?.endedAt
                    ?.toIso8601String(),
                'product_snapshot': snapshot,
                'dynamic_values': dynamicValues,
                'gross_weight': computation.gross,
                'tare_weight': computation.tare,
                'net_weight': computation.net,
                'piece_quantity': computation.roundedPieces,
                'raw_reading': reading.toJson(),
                'captured_at': now.toIso8601String(),
              }),
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (inwardSession != null) {
        await _refreshSessionTotals(inwardSession.id);
      }
    });

    return id;
  }

  Future<LocalInwardSession> startSession() async {
    final now = DateTime.now();
    final id = const Uuid().v7();
    final number =
        'INW-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.microsecondsSinceEpoch}';
    await database
        .into(database.localInwardSessions)
        .insert(
          LocalInwardSessionsCompanion.insert(
            id: id,
            sessionNumber: number,
            startedAt: now,
          ),
        );
    return (database.select(
      database.localInwardSessions,
    )..where((row) => row.id.equals(id))).getSingle();
  }

  Future<LocalInwardSession?> openSession() {
    return (database.select(database.localInwardSessions)
          ..where((row) => row.status.equals('open'))
          ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<LocalInwardSession> finishSession(String sessionId) async {
    await _refreshSessionTotals(sessionId, close: true);
    final session = await (database.select(
      database.localInwardSessions,
    )..where((row) => row.id.equals(sessionId))).getSingle();
    await _queueInwardSessionSync(session);

    return session;
  }

  Future<List<LocalInwardSession>> sessions({int limit = 50}) {
    return (database.select(database.localInwardSessions)
          ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> _refreshSessionTotals(
    String sessionId, {
    bool close = false,
  }) async {
    final rows = await (database.select(
      database.localProductionTransactions,
    )..where((row) => row.inwardSessionId.equals(sessionId))).get();
    await (database.update(
      database.localInwardSessions,
    )..where((row) => row.id.equals(sessionId))).write(
      LocalInwardSessionsCompanion(
        status: Value(close ? 'saved' : 'open'),
        entryCount: Value(rows.length),
        totalGrossWeight: Value(
          rows.fold(0, (sum, row) => sum + row.grossWeight),
        ),
        totalTareWeight: Value(
          rows.fold(0, (sum, row) => sum + row.tareWeight),
        ),
        totalNetWeight: Value(rows.fold(0, (sum, row) => sum + row.netWeight)),
        totalPieceQuantity: Value(
          rows.fold<double>(0, (sum, row) => sum + (row.pieceQuantity ?? 0)),
        ),
        endedAt: close ? Value(DateTime.now()) : const Value.absent(),
      ),
    );
  }

  Future<void> _queueInwardSessionSync(LocalInwardSession session) async {
    final now = DateTime.now();
    final idempotency = 'idem_${session.id}_${session.status}';
    await database
        .into(database.localSyncQueue)
        .insertOnConflictUpdate(
          LocalSyncQueueCompanion.insert(
            id: 'sync_${session.id}',
            entityType: 'inward_session',
            operation: 'update',
            idempotencyKey: idempotency,
            payloadJson: jsonEncode({
              'id': session.id,
              'session_number': session.sessionNumber,
              'status': session.status,
              'entry_count': session.entryCount,
              'total_gross_weight': session.totalGrossWeight,
              'total_tare_weight': session.totalTareWeight,
              'total_net_weight': session.totalNetWeight,
              'total_piece_quantity': session.totalPieceQuantity,
              'started_at': session.startedAt.toIso8601String(),
              'ended_at': session.endedAt?.toIso8601String(),
            }),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<List<LocalProductionTransaction>> recent({int limit = 50}) {
    return (database.select(database.localProductionTransactions)
          ..orderBy([(row) => OrderingTerm.desc(row.capturedAt)])
          ..limit(limit))
        .get();
  }

  Future<List<LocalProductionTransaction>> bySession(String sessionId) {
    return (database.select(database.localProductionTransactions)
          ..where((row) => row.inwardSessionId.equals(sessionId))
          ..orderBy([(row) => OrderingTerm.asc(row.capturedAt)]))
        .get();
  }

  Future<bool> deleteEntry(LocalProductionTransaction row) async {
    if (row.syncStatus == 'synced') {
      final client = apiClient;
      if (client == null) {
        return false;
      }
      await client.delete('/sync/production_transaction/${row.id}');
    }

    await database.transaction(() async {
      await (database.delete(
        database.localSyncQueue,
      )..where((entry) => entry.id.equals('sync_${row.id}'))).go();
      await (database.delete(
        database.localInventoryLedger,
      )..where((entry) => entry.referenceId.equals(row.id))).go();
      await (database.delete(
        database.localProductionTransactions,
      )..where((entry) => entry.id.equals(row.id))).go();
      final sessionId = row.inwardSessionId;
      if (sessionId != null) {
        await _refreshSessionTotals(sessionId);
      }
    });

    return true;
  }

  String _date(DateTime now) =>
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
}
