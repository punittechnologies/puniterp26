import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:punit_tablet/core/database/local_database.dart';
import 'package:punit_tablet/features/dispatch/data/dispatch_repository.dart';
import 'package:punit_tablet/features/inventory/data/inventory_repository.dart';
import 'package:punit_tablet/features/products/domain/product_models.dart';
import 'package:punit_tablet/features/weighing/data/production_repository.dart';
import 'package:punit_tablet/features/weighing/domain/scale_models.dart';
import 'package:punit_tablet/features/weighing/domain/scale_parser.dart';
import 'package:punit_tablet/features/weighing/domain/weighing_logic.dart';
import 'package:punit_tablet/services/sync/sync_queue_service.dart';

void main() {
  test('buffers partial packets and parses stable scale readings', () {
    const profile = ScaleParsingProfile(id: 'p1', name: 'Default');
    final buffer = ScalePacketBuffer(profile);
    final parser = ScaleReadingParser(profile);

    expect(buffer.addBytes('ST,GS,+001'.codeUnits), isEmpty);
    final packets = buffer.addBytes('2.340kg\nUS,GS,+0013.000kg\n'.codeUnits);

    expect(packets.length, 2);
    final reading = parser.parse(packets.first);
    expect(reading?.grossWeight, 12.34);
    expect(reading?.isStable, isTrue);
  });

  test('detects stable readings after duration and tolerance', () {
    final detector = WeightStabilityDetector(
      duration: const Duration(milliseconds: 500),
      tolerance: 0.05,
    );
    final first = DateTime(2026);
    expect(
      detector.add(
        ScaleReading(
          grossWeight: 10,
          unit: 'kg',
          isStable: true,
          raw: 'a',
          recordedAt: first,
        ),
      ),
      isFalse,
    );
    expect(
      detector.add(
        ScaleReading(
          grossWeight: 10.02,
          unit: 'kg',
          isStable: true,
          raw: 'b',
          recordedAt: first.add(const Duration(milliseconds: 600)),
        ),
      ),
      isTrue,
    );
  });

  test('infers stability numerically when scale sends no stability marker', () {
    const profile = ScaleParsingProfile(
      id: 'numeric-only',
      name: 'Numeric only',
      stableTokens: ['ST'],
      unstableTokens: ['US'],
    );
    final parsed = const ScaleReadingParser(profile).parse('+0.845kg\n');

    expect(parsed, isNotNull);
    expect(parsed!.isStable, isFalse);
    expect(parsed.stabilitySignalPresent, isFalse);

    final detector = WeightStabilityDetector(
      duration: const Duration(milliseconds: 500),
      tolerance: 0.02,
    );
    final first = DateTime(2026);
    expect(
      detector.add(
        ScaleReading(
          grossWeight: 0.845,
          unit: 'kg',
          isStable: false,
          stabilitySignalPresent: false,
          raw: '+0.845kg',
          recordedAt: first,
        ),
      ),
      isFalse,
    );
    expect(
      detector.add(
        ScaleReading(
          grossWeight: 0.846,
          unit: 'kg',
          isStable: false,
          stabilitySignalPresent: false,
          raw: '+0.846kg',
          recordedAt: first.add(const Duration(milliseconds: 600)),
        ),
      ),
      isTrue,
    );
  });

  test('explicit unstable scale signal still blocks numerical fallback', () {
    final detector = WeightStabilityDetector(
      duration: const Duration(milliseconds: 500),
      tolerance: 0.02,
    );
    final first = DateTime(2026);
    expect(
      detector.add(
        ScaleReading(
          grossWeight: 0.845,
          unit: 'kg',
          isStable: false,
          raw: 'US,+0.845kg',
          recordedAt: first,
        ),
      ),
      isFalse,
    );
    expect(
      detector.add(
        ScaleReading(
          grossWeight: 0.845,
          unit: 'kg',
          isStable: false,
          raw: 'US,+0.845kg',
          recordedAt: first.add(const Duration(seconds: 1)),
        ),
      ),
      isFalse,
    );
  });

  test('weight range blocks both automatic and manual capture paths', () {
    final first = DateTime(2026);
    const computation = WeightComputation(
      gross: 8,
      tare: 0,
      net: 8,
      unit: 'kg',
      rangeStatus: WeightRangeStatus.underweight,
    );
    ScaleReading readingAt(int milliseconds) => ScaleReading(
      grossWeight: 8,
      unit: 'kg',
      isStable: true,
      raw: 'ST,+8kg',
      recordedAt: first.add(Duration(milliseconds: milliseconds)),
    );

    final autoSession = WeighingSession(
      stabilityDuration: const Duration(milliseconds: 500),
    );
    expect(autoSession.update(readingAt(0), computation), isFalse);
    expect(autoSession.update(readingAt(600), computation), isFalse);
    expect(autoSession.state, CaptureState.validated);
    expect(WeighingController.isWithinAllowedRange(computation), isFalse);
    expect(
      WeighingController.isWithinAllowedRange(
        const WeightComputation(
          gross: 10,
          tare: 0,
          net: 10,
          unit: 'kg',
          rangeStatus: WeightRangeStatus.accepted,
        ),
      ),
      isTrue,
    );
    expect(
      WeighingController.isWithinAllowedRange(
        const WeightComputation(
          gross: 10,
          tare: 0,
          net: 10,
          unit: 'kg',
          rangeStatus: WeightRangeStatus.noRule,
        ),
      ),
      isTrue,
    );
  });

  test('auto capture requests save and print only for a ready reading', () {
    expect(
      WeighingController.shouldAutoSaveAndPrint(
        autoCaptureEnabled: true,
        readingReady: true,
      ),
      isTrue,
    );
    expect(
      WeighingController.shouldAutoSaveAndPrint(
        autoCaptureEnabled: true,
        readingReady: false,
      ),
      isFalse,
    );
    expect(
      WeighingController.shouldAutoSaveAndPrint(
        autoCaptureEnabled: false,
        readingReady: true,
      ),
      isFalse,
    );
  });

  test('captures production locally and adds inventory', () async {
    final database = LocalDatabase.memory();
    final production = ProductionRepository(database: database);
    final inventory = InventoryRepository(database);
    final product = ProductConfig.fromJson({
      'id': 'p1',
      'name': 'Pipe',
      'product_code': 'PIPE',
      'is_active': true,
      'effective': {'tare_weight': '1.000'},
      'variants': [],
    });
    final computation = const WeightComputation(
      gross: 11,
      tare: 1,
      net: 10,
      unit: 'kg',
      rangeStatus: WeightRangeStatus.accepted,
      roundedPieces: '20',
    );
    final reading = ScaleReading(
      grossWeight: 11,
      unit: 'kg',
      isStable: true,
      raw: 'ST,+11kg',
      recordedAt: DateTime.now(),
    );

    await production.capture(
      product: product,
      computation: computation,
      reading: reading,
    );

    expect((await production.recent()).single.netWeight, 10);
    expect(await inventory.productWeight('p1'), 10);
  });

  test('finishing inward session queues session sync', () async {
    final database = LocalDatabase.memory();
    final production = ProductionRepository(database: database);
    final product = ProductConfig.fromJson({
      'id': 'p1',
      'name': 'Pipe',
      'product_code': 'PIPE',
      'is_active': true,
      'effective': {'tare_weight': '1.000'},
      'variants': [],
    });
    final computation = const WeightComputation(
      gross: 11,
      tare: 1,
      net: 10,
      unit: 'kg',
      rangeStatus: WeightRangeStatus.accepted,
      roundedPieces: '20',
    );
    final reading = ScaleReading(
      grossWeight: 11,
      unit: 'kg',
      isStable: true,
      raw: 'ST,+11kg',
      recordedAt: DateTime.now(),
    );

    final session = await production.startSession();
    await production.capture(
      product: product,
      computation: computation,
      reading: reading,
      inwardSession: session,
    );
    final finished = await production.finishSession(session.id);
    final queued = await (database.select(
      database.localSyncQueue,
    )..where((row) => row.entityType.equals('inward_session'))).getSingle();

    expect(finished.status, 'saved');
    expect(finished.entryCount, 1);
    expect(queued.payloadJson, contains('"session_number"'));
  });

  test('account-scoped repositories hide legacy operational data', () async {
    final database = LocalDatabase.memory();
    final now = DateTime.now();
    await database
        .into(database.localProductionTransactions)
        .insert(
          LocalProductionTransactionsCompanion.insert(
            id: 'old-production',
            accountScope: const Value('legacy'),
            serialNumber: 'OLD-1',
            barcodeValue: 'OLD-1',
            productId: 'old-product',
            productSnapshotJson: '{}',
            grossWeight: 1,
            tareWeight: 0,
            netWeight: 1,
            idempotencyKey: 'old-production-idem',
            rawReadingJson: '{}',
            capturedAt: now,
          ),
        );
    await database
        .into(database.localSyncQueue)
        .insert(
          LocalSyncQueueCompanion.insert(
            id: 'old-sync',
            accountScope: const Value('legacy'),
            entityType: 'production_transaction',
            operation: 'create',
            idempotencyKey: 'old-sync-idem',
            payloadJson: '{}',
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(await ProductionRepository(database: database).recent(), isEmpty);
    expect(await SyncQueueService(database).pendingCount(), 0);
  });

  test('dispatch rejects already dispatched barcode', () async {
    final database = LocalDatabase.memory();
    final production = ProductionRepository(database: database);
    final dispatch = DispatchRepository(database);
    final product = ProductConfig.fromJson({
      'id': 'p1',
      'name': 'Pipe',
      'product_code': 'PIPE',
      'is_active': true,
      'effective': <String, dynamic>{},
      'variants': [],
    });
    final computation = const WeightComputation(
      gross: 10,
      tare: 0,
      net: 10,
      unit: 'kg',
      rangeStatus: WeightRangeStatus.accepted,
    );
    final reading = ScaleReading(
      grossWeight: 10,
      unit: 'kg',
      isStable: true,
      raw: 'ST,+10kg',
      recordedAt: DateTime.now(),
    );
    await production.capture(
      product: product,
      computation: computation,
      reading: reading,
    );
    final item = (await production.recent()).single;
    final customer = LocalCustomer(
      id: 'c1',
      name: 'Acme',
      code: 'AC',
      payloadJson: '{}',
      isActive: true,
    );
    await database
        .into(database.localCustomers)
        .insert(
          LocalCustomersCompanion.insert(
            id: customer.id,
            name: customer.name,
            code: const Value('AC'),
            payloadJson: '{}',
          ),
        );

    await dispatch.confirmDispatch(customer: customer, items: [item]);

    expect(await dispatch.findAvailableBarcode(item.barcodeValue), isNull);
  });
}
