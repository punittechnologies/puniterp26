import 'package:flutter_test/flutter_test.dart';
import 'package:punit_tablet/core/database/local_database.dart';
import 'package:punit_tablet/core/demo/trial_data_seeder.dart';

void main() {
  test('seeds trial data into a fresh local database', () async {
    final database = LocalDatabase.memory();
    addTearDown(database.close);

    await TrialDataSeeder(database).seedIfEmpty();

    expect(await database.select(database.localProducts).get(), hasLength(2));
    expect(
      await database.select(database.localProductVariants).get(),
      hasLength(3),
    );
    expect(
      await database.select(database.localDynamicFields).get(),
      hasLength(5),
    );
    expect(
      await database.select(database.localLabelTemplates).get(),
      hasLength(1),
    );
    expect(await database.select(database.localCustomers).get(), hasLength(1));
    expect(
      await database.select(database.localInwardSessions).get(),
      hasLength(1),
    );
    expect(
      await database.select(database.localProductionTransactions).get(),
      hasLength(3),
    );
    expect(await database.select(database.localDispatches).get(), hasLength(1));
    expect(
      await database.select(database.localInventoryLedger).get(),
      hasLength(4),
    );
  });
}
