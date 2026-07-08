import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../core/api/api_client.dart';
import '../../core/database/local_database.dart';

class SyncQueueService {
  const SyncQueueService(this.database, {this.apiClient});

  final LocalDatabase database;
  final ApiClient? apiClient;

  Future<int> pendingCount() async {
    final entries =
        await (database.select(database.localSyncQueue)..where(
              (entry) =>
                  entry.status.equals('pending') |
                  entry.status.equals('failed'),
            ))
            .get();
    return entries.length;
  }

  Future<List<LocalSyncQueueData>> failed() {
    return (database.select(database.localSyncQueue)
          ..where((entry) => entry.status.equals('failed'))
          ..orderBy([(entry) => OrderingTerm.desc(entry.updatedAt)]))
        .get();
  }

  Future<SyncRetrySummary> retryPending({int passes = 3}) async {
    final client = apiClient;
    if (client == null) return const SyncRetrySummary();
    var synced = 0;
    var failed = 0;
    final errors = <String>[];
    for (var pass = 0; pass < passes; pass++) {
      final entries = await _pendingInSyncOrder();
      if (entries.isEmpty) break;
      var passFailures = 0;
      for (final entry in entries) {
        try {
          final decodedPayload = jsonDecode(entry.payloadJson);
          await client.post(
            '/sync/${entry.entityType}',
            data: decodedPayload,
            idempotencyKey: entry.idempotencyKey,
          );
          await (database.update(
            database.localSyncQueue,
          )..where((row) => row.id.equals(entry.id))).write(
            LocalSyncQueueCompanion(
              status: const Value('synced'),
              attemptCount: Value(entry.attemptCount + 1),
              updatedAt: Value(DateTime.now()),
            ),
          );
          await _markLocalEntitySynced(entry.entityType, decodedPayload);
          await (database.delete(
            database.localSyncQueue,
          )..where((row) => row.id.equals(entry.id))).go();
          synced++;
        } catch (error) {
          passFailures++;
          failed++;
          errors.add('${entry.entityType}: ${_syncErrorMessage(error)}');
          await (database.update(
            database.localSyncQueue,
          )..where((row) => row.id.equals(entry.id))).write(
            LocalSyncQueueCompanion(
              status: const Value('failed'),
              attemptCount: Value(entry.attemptCount + 1),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
      if (passFailures == entries.length) break;
    }
    return SyncRetrySummary(synced: synced, failed: failed, errors: errors);
  }

  Future<List<LocalSyncQueueData>> _pendingInSyncOrder() async {
    final entries =
        await (database.select(database.localSyncQueue)..where(
              (entry) =>
                  entry.status.equals('pending') |
                  entry.status.equals('failed'),
            ))
            .get();
    entries.sort((a, b) {
      final priority = _priority(
        a.entityType,
      ).compareTo(_priority(b.entityType));
      if (priority != 0) return priority;
      return a.createdAt.compareTo(b.createdAt);
    });
    return entries;
  }

  int _priority(String entityType) {
    return switch (entityType) {
      'production_transaction' => 0,
      'inward_session' => 1,
      'dispatch' => 2,
      _ => 9,
    };
  }

  Future<void> _markLocalEntitySynced(
    String entityType,
    dynamic decodedPayload,
  ) async {
    if (decodedPayload is! Map<String, dynamic>) return;
    final id = decodedPayload['id']?.toString();
    if (id == null || id.isEmpty) return;

    if (entityType == 'production_transaction') {
      await (database.update(
        database.localProductionTransactions,
      )..where((row) => row.id.equals(id))).write(
        const LocalProductionTransactionsCompanion(
          syncStatus: Value('synced'),
          status: Value('synced'),
        ),
      );
      final sessionId = decodedPayload['inward_session_id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        await _purgeProduction(id);
      }
      return;
    }

    if (entityType == 'dispatch') {
      await _purgeDispatch(id);
      return;
    }

    if (entityType == 'inward_session') {
      await (database.update(database.localInwardSessions)
            ..where((row) => row.id.equals(id)))
          .write(const LocalInwardSessionsCompanion(status: Value('synced')));
      await _purgeInwardSessionIfComplete(id);
      return;
    }
  }

  Future<void> _purgeInwardSessionIfComplete(String sessionId) async {
    final rows = await (database.select(
      database.localProductionTransactions,
    )..where((row) => row.inwardSessionId.equals(sessionId))).get();
    final ids = rows.map((row) => row.id).toSet();

    for (final productionId in ids) {
      final pending =
          await (database.select(database.localSyncQueue)..where(
                (row) =>
                    row.id.equals('sync_$productionId') &
                    (row.status.equals('pending') |
                        row.status.equals('failed')),
              ))
              .getSingleOrNull();
      if (pending != null) {
        return;
      }
    }

    await database.transaction(() async {
      for (final productionId in ids) {
        await _purgeProduction(productionId);
      }
      await (database.delete(
        database.localInwardSessions,
      )..where((row) => row.id.equals(sessionId))).go();
    });
  }

  Future<void> _purgeProduction(String productionId) async {
    await (database.delete(
      database.localInventoryLedger,
    )..where((row) => row.referenceId.equals(productionId))).go();
    await (database.delete(
      database.localProductionTransactions,
    )..where((row) => row.id.equals(productionId))).go();
    await (database.delete(
      database.localSyncQueue,
    )..where((row) => row.id.equals('sync_$productionId'))).go();
  }

  Future<void> _purgeDispatch(String dispatchId) async {
    await database.transaction(() async {
      await (database.delete(
        database.localDispatchItems,
      )..where((row) => row.dispatchId.equals(dispatchId))).go();
      await (database.delete(
        database.localInventoryLedger,
      )..where((row) => row.referenceId.equals(dispatchId))).go();
      await (database.delete(
        database.localDispatches,
      )..where((row) => row.id.equals(dispatchId))).go();
      await (database.delete(
        database.localSyncQueue,
      )..where((row) => row.id.equals('sync_$dispatchId'))).go();
    });
  }

  String _syncErrorMessage(Object error) {
    if (error is DioException) {
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
      final status = error.response?.statusCode;
      if (status != null) return 'server returned HTTP $status';
      return 'network connection failed';
    }

    return error.toString();
  }
}

class SyncRetrySummary {
  const SyncRetrySummary({
    this.synced = 0,
    this.failed = 0,
    this.errors = const [],
  });

  final int synced;
  final int failed;
  final List<String> errors;

  bool get hasFailures => failed > 0;

  String get message => errors.join('\n');
}
