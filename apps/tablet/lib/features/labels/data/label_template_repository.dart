import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';
import '../../../core/config/app_edition.dart';
import '../../../core/database/local_database.dart';
import '../domain/label_template_models.dart';

class LabelTemplateRepository {
  const LabelTemplateRepository({
    required this.database,
    this.apiClient,
    this.webManagedOnly = AppEdition.webManagedLabels,
  });

  static const _selectedTemplatePrefix = 'label.selected_template_id';
  static const _legacySelectedTemplateKey = 'label.selected_template_id';

  final LocalDatabase database;
  final ApiClient? apiClient;
  final bool webManagedOnly;

  Future<List<LabelTemplateConfig>> cachedTemplates() async {
    final localId = await _localTemplateId();
    final rows = await database.select(database.localLabelTemplates).get();
    return rows
        .where((row) {
          if (row.id.startsWith('local_') && row.id != localId) {
            return false;
          }

          return true;
        })
        .map(
          (row) => LabelTemplateConfig.fromJson(
            jsonDecode(row.payloadJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<String?> selectedTemplateId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(await _selectedTemplateKey());
    } catch (_) {
      return null;
    }
  }

  Future<void> selectTemplate(String templateId) async {
    await (await SharedPreferences.getInstance()).setString(
      await _selectedTemplateKey(),
      templateId,
    );
  }

  Future<LabelTemplateConfig?> effective({
    String? productId,
    String? variantId,
    bool preferServerTemplates = false,
  }) async {
    final templates = await cachedTemplates();
    final selectedId = await selectedTemplateId();
    final localId = await _localTemplateId();
    final accountCode = 'APP-LABEL-${await _accountScopeForCode()}';
    LabelTemplateConfig? find(
      bool Function(LabelTemplateConfig template) test,
    ) {
      for (final template in templates) {
        if (test(template)) return template;
      }
      return null;
    }

    if (webManagedOnly) {
      return find((template) => template.id == selectedId);
    }

    final serverResolved =
        find(
          (template) =>
              template.scope == 'variant' && template.variantId == variantId,
        ) ??
        find(
          (template) =>
              template.scope == 'product' && template.productId == productId,
        ) ??
        find((template) => template.scope == 'tenant' && template.isDefault) ??
        find((template) => template.scope == 'system' && template.isDefault);

    if (preferServerTemplates && serverResolved != null) {
      return serverResolved;
    }

    return find((template) => template.id == selectedId) ??
        find((template) => template.code == accountCode) ??
        find((template) => template.id == localId) ??
        serverResolved;
  }

  Future<void> activatePayload(Map<String, dynamic> payload) async {
    final localId = await _localTemplateId();
    await database.transaction(() async {
      final localTemplates = await (database.select(
        database.localLabelTemplates,
      )..where((row) => row.id.equals(localId))).get();
      await database.delete(database.localLabelTemplates).go();
      final rawTemplates = payload['templates'];
      final templates = rawTemplates is Map<String, dynamic>
          ? rawTemplates['data'] as List<dynamic>? ?? const []
          : rawTemplates as List<dynamic>? ?? const [];
      final appDefaultTemplateId = webManagedOnly
          ? _webDefaultTemplateId(templates)
          : payload['appDefaultTemplateId']?.toString();
      final hasCloudAppDefault =
          appDefaultTemplateId != null && appDefaultTemplateId.isNotEmpty;

      for (final raw in templates) {
        final template = raw as Map<String, dynamic>;
        await database
            .into(database.localLabelTemplates)
            .insert(
              LocalLabelTemplatesCompanion.insert(
                id: template['id'] as String,
                code: template['code'] as String,
                name: template['name'] as String,
                scope: template['scope'] as String,
                productId: Value(template['productId'] as String?),
                variantId: Value(template['variantId'] as String?),
                activeVersion: Value(
                  _asInt(template['activeVersion'], fallback: 1),
                ),
                isDefault: Value(_asBool(template['isDefault'])),
                payloadJson: jsonEncode(template),
              ),
            );
      }
      if (!hasCloudAppDefault && !webManagedOnly) {
        for (final template in localTemplates) {
          await database
              .into(database.localLabelTemplates)
              .insertOnConflictUpdate(
                LocalLabelTemplatesCompanion.insert(
                  id: template.id,
                  code: template.code,
                  name: template.name,
                  scope: template.scope,
                  productId: Value(template.productId),
                  variantId: Value(template.variantId),
                  activeVersion: Value(template.activeVersion),
                  isDefault: Value(template.isDefault),
                  payloadJson: template.payloadJson,
                ),
              );
        }
      }
      if (hasCloudAppDefault) {
        await selectTemplate(appDefaultTemplateId);
      } else {
        final selectedId = await selectedTemplateId();
        final selectedStillExists =
            selectedId != null &&
            await (database.select(database.localLabelTemplates)
                      ..where((row) => row.id.equals(selectedId)))
                    .getSingleOrNull() !=
                null;
        if (!selectedStillExists) {
          await (await SharedPreferences.getInstance()).remove(
            await _selectedTemplateKey(),
          );
        }
      }
      await (database.delete(
        database.localConfigurationVersions,
      )..where((row) => row.scope.equals('label_templates'))).go();
      await database
          .into(database.localConfigurationVersions)
          .insert(
            LocalConfigurationVersionsCompanion.insert(
              id: 'label_templates',
              scope: 'label_templates',
              version: payload['configurationVersion'] as int? ?? 1,
              activatedAt: DateTime.now(),
            ),
          );
    });
  }

  Future<void> sync() async {
    final client = apiClient ?? await ApiSession.client();
    if (client == null) return;
    final response = await client.get('/sync/label-templates');
    await activatePayload(response.data as Map<String, dynamic>);
  }

  Future<void> saveLocalTenantDefault({
    required String name,
    required Map<String, dynamic> templateJson,
  }) async {
    if (webManagedOnly) {
      throw StateError(
        'Label templates for this edition are managed in the web panel.',
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final localId = await _localTemplateId();
    final accountScope = await _accountScope();
    final template = {
      'id': localId,
      'name': name,
      'code': 'LOCAL-TABLET-LABEL-$accountScope',
      'scope': 'tenant',
      'productId': null,
      'variantId': null,
      'activeVersion': now,
      'isDefault': true,
      'templateJson': templateJson,
    };
    await selectTemplate(localId);
    await database
        .into(database.localLabelTemplates)
        .insertOnConflictUpdate(
          LocalLabelTemplatesCompanion.insert(
            id: localId,
            code: 'LOCAL-TABLET-LABEL-$accountScope',
            name: name,
            scope: 'tenant',
            activeVersion: Value(now),
            isDefault: const Value(true),
            payloadJson: jsonEncode(template),
          ),
        );
    await _saveCloudTenantDefault(name: name, templateJson: templateJson);
  }

  Future<void> _saveCloudTenantDefault({
    required String name,
    required Map<String, dynamic> templateJson,
  }) async {
    final client = apiClient ?? await ApiSession.client();
    if (client == null) {
      throw StateError('Login is required to save label templates.');
    }

    final response = await client.post(
      '/label-templates/app-default',
      data: {'name': name, 'template_json': templateJson},
    );
    final template = _templatePayload(response.data);
    await database
        .into(database.localLabelTemplates)
        .insertOnConflictUpdate(
          LocalLabelTemplatesCompanion.insert(
            id: template['id'] as String,
            code: template['code'] as String,
            name: template['name'] as String,
            scope: template['scope'] as String,
            productId: Value(template['productId'] as String?),
            variantId: Value(template['variantId'] as String?),
            activeVersion: Value(
              _asInt(template['activeVersion'], fallback: 1),
            ),
            isDefault: Value(_asBool(template['isDefault'])),
            payloadJson: jsonEncode(template),
          ),
        );
    await selectTemplate(template['id'] as String);
  }

  Map<String, dynamic> _templatePayload(Object? data) {
    if (data is Map<String, dynamic>) {
      final wrapped = data['data'];
      if (wrapped is Map<String, dynamic>) return wrapped;
      return data;
    }

    throw const FormatException('Invalid label template save response.');
  }

  Future<void> clearLocalAccountState({bool allAccounts = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final localId = await _localTemplateId();
    if (allAccounts) {
      for (final key in prefs.getKeys()) {
        if (key == _legacySelectedTemplateKey ||
            key.startsWith('$_selectedTemplatePrefix.')) {
          await prefs.remove(key);
        }
      }
    } else {
      await prefs.remove(await _selectedTemplateKey());
    }
    if (allAccounts) {
      await database.delete(database.localLabelTemplates).go();
      await (database.delete(
        database.localConfigurationVersions,
      )..where((row) => row.scope.equals('label_templates'))).go();
      return;
    }
    await (database.delete(
      database.localLabelTemplates,
    )..where((row) => row.id.equals(localId))).go();
  }

  Future<String> _selectedTemplateKey() async =>
      '$_selectedTemplatePrefix.${await _accountScope()}';

  Future<String> currentLocalTemplateId() => _localTemplateId();

  Future<String> _localTemplateId() async =>
      'local_label_template_${await _accountScope()}';

  Future<String> _accountScope() async {
    String? email;
    try {
      email = (await ApiSession.email())?.trim().toLowerCase();
    } catch (_) {
      email = null;
    }
    final base = (email == null || email.isEmpty) ? 'anonymous' : email;
    final normalized = base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+$'), '');
    return normalized.isEmpty ? 'anonymous' : normalized;
  }

  Future<String> _accountScopeForCode() async {
    final scope = await _accountScope();
    return scope.replaceAll('_', '-');
  }

  static bool _asBool(Object? value, {bool fallback = false}) {
    return switch (value) {
      bool parsed => parsed,
      int parsed => parsed != 0,
      String parsed => [
        '1',
        'true',
        'yes',
        'y',
      ].contains(parsed.trim().toLowerCase()),
      _ => fallback,
    };
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    return switch (value) {
      int parsed => parsed,
      num parsed => parsed.toInt(),
      String parsed => int.tryParse(parsed) ?? fallback,
      _ => fallback,
    };
  }

  String? _webDefaultTemplateId(List<dynamic> templates) {
    final candidates =
        templates.whereType<Map<String, dynamic>>().where((template) {
          final code = template['code']?.toString() ?? '';
          final scope = template['scope']?.toString() ?? '';
          return !code.startsWith('APP-LABEL-') &&
              _asBool(template['isDefault']) &&
              (scope == 'tenant' || scope == 'system');
        }).toList()..sort((left, right) {
          final leftScope = left['scope'] == 'tenant' ? 0 : 1;
          final rightScope = right['scope'] == 'tenant' ? 0 : 1;
          final scopeOrder = leftScope.compareTo(rightScope);
          if (scopeOrder != 0) return scopeOrder;
          final updatedOrder = _updatedAtMillis(
            right['updatedAt'],
          ).compareTo(_updatedAtMillis(left['updatedAt']));
          if (updatedOrder != 0) return updatedOrder;
          return _asInt(
            right['activeVersion'],
          ).compareTo(_asInt(left['activeVersion']));
        });

    return candidates.firstOrNull?['id']?.toString();
  }

  int _updatedAtMillis(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
}
