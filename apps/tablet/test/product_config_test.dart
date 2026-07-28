import 'package:flutter_test/flutter_test.dart';
import 'package:punit_tablet/core/database/local_database.dart';
import 'package:punit_tablet/features/products/data/product_repository.dart';
import 'package:punit_tablet/features/products/domain/conversion_calculator.dart';
import 'package:punit_tablet/features/products/domain/product_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('parses product and variant effective values', () {
    final product = ProductConfig.fromJson({
      'id': 'p1',
      'name': 'Rod',
      'product_code': 'ROD',
      'is_active': 1,
      'effective': {'tare_weight': '1.000', 'minimum_weight': '5.000'},
      'variants': [
        {
          'id': 'v1',
          'product_id': 'p1',
          'name': 'Blue',
          'variant_code': 'ROD-BLUE',
          'effective': {'tare_weight': '2.000'},
        },
      ],
    });

    expect(product.effective.tareWeight, '1.000');
    expect(product.isActive, isTrue);
    expect(product.variants.single.effective.tareWeight, '2.000');
  });

  test('conversion calculator matches expected rounding', () {
    final calculator = ConversionCalculator();
    final result = calculator.calculate(
      netWeight: 10.25,
      rule: {
        'method': 'pieces_per_kg',
        'pieces_per_kg': '3',
        'rounding_method': 'nearest',
        'decimal_places': 0,
      },
    );

    expect(result['rounded_quantity'], '31');
  });

  test(
    'activates product configuration transactionally in local database',
    () async {
      final database = LocalDatabase.memory();
      final repository = ProductRepository(database: database);

      await repository.activatePayload({
        'configurationVersion': 2,
        'products': [
          {
            'id': 'p1',
            'name': 'Pipe',
            'product_code': 'PIPE',
            'is_active': true,
            'configuration_version': 2,
            'effective': {'tare_weight': '0.000'},
            'variants': [],
          },
        ],
        'dynamicFields': [
          {
            'id': 'f1',
            'entity_type': 'product',
            'internal_key': 'heat_no',
            'field_label': 'Heat No',
            'data_type': 'short_text',
            'visible_in_flutter': 1,
            'editable_in_flutter': 1,
          },
        ],
      });

      final products = await repository.cachedProducts();
      final fields = await repository.cachedFields();

      expect(products.single.productCode, 'PIPE');
      expect(fields.single.internalKey, 'heat_no');
    },
  );

  test('sync accepts simplified web products without product code', () async {
    final database = LocalDatabase.memory();
    final repository = ProductRepository(database: database);

    await repository.activatePayload({
      'configurationVersion': 3,
      'products': [
        {
          'id': 'p-simple',
          'name': 'Building Roll',
          'product_code': null,
          'is_active': true,
          'configuration_version': 3,
          'effective': {'tare_weight': '0.000'},
          'variants': [
            {
              'id': 'v-simple',
              'product_id': 'p-simple',
              'name': 'Blue 350',
              'variant_code': null,
              'effective': {'tare_weight': '0.000'},
            },
          ],
        },
      ],
      'dynamicFields': [],
    });

    final product = (await repository.cachedProducts()).single;
    expect(product.name, 'Building Roll');
    expect(product.productCode, 'BUI');
    expect(product.variants.single.variantCode, 'BLU');
  });

  test('dynamic fields accept dropdown options sent as json string', () {
    final field = DynamicFieldConfig.fromJson({
      'id': 'field-1',
      'entity_type': 'product_variant',
      'internal_key': 'color',
      'field_label': 'Color',
      'data_type': 'dropdown',
      'is_required': 0,
      'editable_in_flutter': 1,
      'dropdown_options': '[{"label":"Red","value":"red"}]',
    });

    expect(field.options.single['label'], 'Red');
    expect(field.options.single['value'], 'red');
  });

  test(
    'replaces old demo configuration version by scope during sync',
    () async {
      final database = LocalDatabase.memory();
      final repository = ProductRepository(database: database);
      await database
          .into(database.localConfigurationVersions)
          .insert(
            LocalConfigurationVersionsCompanion.insert(
              id: 'demo_products',
              scope: 'products',
              version: 1,
              activatedAt: DateTime(2026),
            ),
          );

      await repository.activatePayload({
        'configurationVersion': 2,
        'products': [
          {
            'id': 'p2',
            'name': 'Live Product',
            'product_code': 'LIVE',
            'is_active': 1,
            'configuration_version': 2,
            'effective': {'tare_weight': '0.000'},
            'variants': [],
          },
        ],
        'dynamicFields': [],
      });

      final versions = await database
          .select(database.localConfigurationVersions)
          .get();
      expect(versions.single.id, 'products');
      expect((await repository.cachedProducts()).single.name, 'Live Product');
    },
  );

  test('keeps cached batches isolated between signed-in accounts', () async {
    SharedPreferences.setMockInitialValues({
      'api_account_scope': 'tenant-a:user-a',
    });
    final database = LocalDatabase.memory();
    final repository = ProductRepository(database: database);

    await repository.activatePayload({
      'configurationVersion': 4,
      'products': [],
      'dynamicFields': [],
      'batches': [
        {'id': 'batch-a', 'name': 'Batch A', 'products': []},
      ],
    });

    expect((await repository.cachedBatches()).single['name'], 'Batch A');

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('api_account_scope', 'tenant-b:user-b');
    expect(await repository.cachedBatches(), isEmpty);

    await preferences.setString('api_account_scope', 'tenant-a:user-a');
    expect((await repository.cachedBatches()).single['name'], 'Batch A');
  });
}
