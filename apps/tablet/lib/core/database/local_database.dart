import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

class LocalSyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get accountScope => text().withDefault(const Constant('legacy'))();
  TextColumn get entityType => text()();
  TextColumn get operation => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalConfigurationVersions extends Table {
  TextColumn get id => text()();
  TextColumn get scope => text().unique()();
  IntColumn get version => integer()();
  DateTimeColumn get activatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get productCode => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get payloadJson => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get configurationVersion =>
      integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  TextColumn get variantCode => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalDynamicFields extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get internalKey => text()();
  TextColumn get fieldLabel => text()();
  TextColumn get dataType => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get visibleInFlutter =>
      boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalLabelTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get scope => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get variantId => text().nullable()();
  IntColumn get activeVersion => integer().withDefault(const Constant(1))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalScaleProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalInwardSessions extends Table {
  TextColumn get id => text()();
  TextColumn get accountScope => text().withDefault(const Constant('legacy'))();
  TextColumn get sessionNumber => text().unique()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  IntColumn get entryCount => integer().withDefault(const Constant(0))();
  RealColumn get totalGrossWeight => real().withDefault(const Constant(0))();
  RealColumn get totalTareWeight => real().withDefault(const Constant(0))();
  RealColumn get totalNetWeight => real().withDefault(const Constant(0))();
  RealColumn get totalPieceQuantity => real().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalProductionTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountScope => text().withDefault(const Constant('legacy'))();
  TextColumn get serialNumber => text().unique()();
  TextColumn get labelSerialNumber => text().nullable()();
  TextColumn get barcodeValue => text().unique()();
  TextColumn get productId => text()();
  TextColumn get variantId => text().nullable()();
  TextColumn get inwardSessionId => text().nullable()();
  TextColumn get productSnapshotJson => text()();
  TextColumn get dynamicValuesJson =>
      text().withDefault(const Constant('{}'))();
  RealColumn get grossWeight => real()();
  RealColumn get tareWeight => real()();
  RealColumn get netWeight => real()();
  RealColumn get pieceQuantity => real().nullable()();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  TextColumn get status => text().withDefault(const Constant('local'))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get rawReadingJson => text()();
  DateTimeColumn get capturedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalInventoryLedger extends Table {
  TextColumn get id => text()();
  TextColumn get accountScope => text().withDefault(const Constant('legacy'))();
  TextColumn get productId => text()();
  TextColumn get variantId => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get labelSerialNumber => text().nullable()();
  TextColumn get barcodeValue => text().nullable()();
  TextColumn get transactionType => text()();
  RealColumn get weightQuantity => real()();
  RealColumn get pieceQuantity => real().nullable()();
  TextColumn get referenceType => text()();
  TextColumn get referenceId => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get payloadJson => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalDispatches extends Table {
  TextColumn get id => text()();
  TextColumn get accountScope => text().withDefault(const Constant('legacy'))();
  TextColumn get dispatchNumber => text().unique()();
  TextColumn get customerId => text()();
  TextColumn get customerSnapshotJson => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  RealColumn get totalWeight => real().withDefault(const Constant(0))();
  RealColumn get totalPieces => real().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get idempotencyKey => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalDispatchItems extends Table {
  TextColumn get id => text()();
  TextColumn get accountScope => text().withDefault(const Constant('legacy'))();
  TextColumn get dispatchId => text()();
  TextColumn get productionTransactionId => text()();
  TextColumn get barcodeValue => text()();
  RealColumn get weightQuantity => real()();
  RealColumn get pieceQuantity => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalSyncQueue,
    LocalConfigurationVersions,
    LocalProducts,
    LocalProductVariants,
    LocalDynamicFields,
    LocalLabelTemplates,
    LocalScaleProfiles,
    LocalInwardSessions,
    LocalProductionTransactions,
    LocalInventoryLedger,
    LocalCustomers,
    LocalDispatches,
    LocalDispatchItems,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  factory LocalDatabase() => _shared ??= LocalDatabase._openShared();

  LocalDatabase._openShared()
    : _closeOnDispose = false,
      super(_openConnection());

  LocalDatabase.memory()
    : _closeOnDispose = true,
      super(NativeDatabase.memory());

  static LocalDatabase? _shared;

  final bool _closeOnDispose;

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 5) {
        await m.createTable(localInwardSessions);
        await m.addColumn(
          localProductionTransactions,
          localProductionTransactions.inwardSessionId,
        );
      }
      if (from < 6) {
        await m.addColumn(localSyncQueue, localSyncQueue.accountScope);
        await m.addColumn(
          localInwardSessions,
          localInwardSessions.accountScope,
        );
        await m.addColumn(
          localProductionTransactions,
          localProductionTransactions.accountScope,
        );
        await m.addColumn(
          localInventoryLedger,
          localInventoryLedger.accountScope,
        );
        await m.addColumn(localDispatches, localDispatches.accountScope);
        await m.addColumn(localDispatchItems, localDispatchItems.accountScope);
      }
      if (from < 7) {
        await m.addColumn(
          localProductionTransactions,
          localProductionTransactions.labelSerialNumber,
        );
        await m.addColumn(
          localInventoryLedger,
          localInventoryLedger.labelSerialNumber,
        );
      }
    },
  );

  @override
  Future<void> close() async {
    if (_closeOnDispose) {
      await super.close();
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'punit_tablet.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
