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
    final repository = LabelTemplateRepository(
      database: database,
      webManagedOnly: false,
    );
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
    final repository = LabelTemplateRepository(
      database: database,
      webManagedOnly: false,
    );
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
    'web label edition selects only the web template marked default',
    () async {
      SharedPreferences.setMockInitialValues({'api_email': 'operator1'});
      final database = LocalDatabase.memory();
      final repository = LabelTemplateRepository(
        database: database,
        webManagedOnly: true,
      );
      await repository.activatePayload({
        'configurationVersion': 8,
        'appDefaultTemplateId': 'app-label',
        'templates': [
          {
            'id': 'app-label',
            'name': 'App Designed Label',
            'code': 'APP-LABEL-operator1',
            'scope': 'tenant',
            'isDefault': true,
            'activeVersion': 99,
            'templateJson': {'widthMm': 50, 'heightMm': 50, 'elements': []},
          },
          {
            'id': 'older-web-label',
            'name': 'Older Web Default',
            'code': 'PACKING-OLD',
            'scope': 'tenant',
            'isDefault': true,
            'activeVersion': 20,
            'updatedAt': '2026-07-20T10:00:00Z',
            'templateJson': {'widthMm': 100, 'heightMm': 100, 'elements': []},
          },
          {
            'id': 'web-label',
            'name': 'Web Default Label',
            'code': 'PACKING-75',
            'scope': 'tenant',
            'isDefault': true,
            'activeVersion': 3,
            'updatedAt': '2026-07-27T10:00:00Z',
            'templateJson': {'widthMm': 75, 'heightMm': 75, 'elements': []},
          },
        ],
      });

      expect(await repository.selectedTemplateId(), 'web-label');
      expect((await repository.effective())?.name, 'Web Default Label');
    },
  );

  test('web label edition clears selection when web has no default', () async {
    SharedPreferences.setMockInitialValues({
      'api_email': 'operator1',
      'label.selected_template_id.operator1': 'old-web-label',
    });
    final database = LocalDatabase.memory();
    final repository = LabelTemplateRepository(
      database: database,
      webManagedOnly: true,
    );
    await repository.activatePayload({
      'configurationVersion': 9,
      'appDefaultTemplateId': 'app-label',
      'templates': [
        {
          'id': 'app-label',
          'name': 'App Designed Label',
          'code': 'APP-LABEL-operator1',
          'scope': 'tenant',
          'isDefault': true,
          'activeVersion': 9,
          'templateJson': {'widthMm': 75, 'heightMm': 75, 'elements': []},
        },
      ],
    });

    expect(await repository.selectedTemplateId(), isNull);
    expect(await repository.effective(), isNull);
  });

  test(
    'clearing all account label state removes stale cached templates',
    () async {
      SharedPreferences.setMockInitialValues({
        'api_email': 'operator1',
        'label.selected_template_id.operator1': 'old-template',
      });
      final database = LocalDatabase.memory();
      final repository = LabelTemplateRepository(
        database: database,
        webManagedOnly: false,
      );
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
