import 'package:flutter_test/flutter_test.dart';
import 'package:punit_tablet/core/database/local_database.dart';
import 'package:punit_tablet/features/labels/data/label_template_repository.dart';
import 'package:punit_tablet/features/labels/domain/label_template_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('parses label template json', () {
    final template = LabelTemplateConfig.fromJson({
      'id': 'l1',
      'name': 'Default',
      'code': 'DEF',
      'scope': 'tenant',
      'isDefault': true,
      'activeVersion': 1,
      'templateJson': {
        'widthMm': 75,
        'heightMm': 75,
        'elements': [
          {
            'key': 'product',
            'type': 'binding_text',
            'bindingKey': 'product.name',
            'x': 5,
            'y': 5,
            'width': 40,
            'height': 10,
          },
        ],
      },
    });

    expect(template.templateJson['widthMm'], 75);
  });

  test('stores templates and resolves offline effective fallback', () async {
    SharedPreferences.setMockInitialValues({});
    final database = LocalDatabase.memory();
    final repository = LabelTemplateRepository(database: database);
    await repository.activatePayload({
      'configurationVersion': 2,
      'templates': [
        {
          'id': 'tenant',
          'name': 'Tenant Default',
          'code': 'TENANT',
          'scope': 'tenant',
          'isDefault': true,
          'activeVersion': 2,
          'templateJson': {'widthMm': 75, 'heightMm': 75, 'elements': []},
        },
        {
          'id': 'variant',
          'name': 'Variant Default',
          'code': 'VARIANT',
          'scope': 'variant',
          'variantId': 'v1',
          'isDefault': false,
          'activeVersion': 2,
          'templateJson': {'widthMm': 50, 'heightMm': 75, 'elements': []},
        },
      ],
    });

    expect((await repository.effective(variantId: 'v1'))?.code, 'VARIANT');
    expect((await repository.effective())?.code, 'TENANT');
  });

  test('server app default template is selected after sync', () async {
    SharedPreferences.setMockInitialValues({'api_email': 'operator1'});
    final database = LocalDatabase.memory();
    final repository = LabelTemplateRepository(database: database);
    await repository.activatePayload({
      'configurationVersion': 5,
      'appDefaultTemplateId': 'app-label',
      'appDefaultTemplateCode': 'APP-LABEL-operator1',
      'templates': [
        {
          'id': 'tenant',
          'name': 'Tenant Default',
          'code': 'TENANT',
          'scope': 'tenant',
          'isDefault': true,
          'activeVersion': 2,
          'templateJson': {'widthMm': 75, 'heightMm': 75, 'elements': []},
        },
        {
          'id': 'app-label',
          'name': 'Operator Saved Label',
          'code': 'APP-LABEL-operator1',
          'scope': 'tenant',
          'isDefault': true,
          'activeVersion': 5,
          'templateJson': {'widthMm': 100, 'heightMm': 150, 'elements': []},
        },
      ],
    });

    final effective = await repository.effective();

    expect(await repository.selectedTemplateId(), 'app-label');
    expect(effective?.code, 'APP-LABEL-operator1');
    expect(effective?.templateJson['widthMm'], 100);
  });

  test(
    'clearing all account label state removes stale cached templates',
    () async {
      SharedPreferences.setMockInitialValues({
        'api_email': 'operator1',
        'label.selected_template_id.operator1': 'old-template',
      });
      final database = LocalDatabase.memory();
      final repository = LabelTemplateRepository(database: database);
      await repository.activatePayload({
        'configurationVersion': 5,
        'appDefaultTemplateId': 'old-template',
        'appDefaultTemplateCode': 'APP-LABEL-operator1',
        'templates': [
          {
            'id': 'old-template',
            'name': 'Operator Label',
            'code': 'APP-LABEL-operator1',
            'scope': 'tenant',
            'isDefault': true,
            'activeVersion': 5,
            'templateJson': {'widthMm': 75, 'heightMm': 75, 'elements': []},
          },
        ],
      });

      await repository.clearLocalAccountState(allAccounts: true);

      expect(await repository.cachedTemplates(), isEmpty);
      expect(await repository.selectedTemplateId(), isNull);
    },
  );
}
