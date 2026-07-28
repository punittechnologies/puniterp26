import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';
import '../../../core/database/local_database.dart';
import '../domain/product_models.dart';

const _cachedProductBatchesPrefix = 'cached_product_batches_json';

class ProductRepository {
  const ProductRepository({required this.database, this.apiClient});

  final LocalDatabase database;
  final ApiClient? apiClient;

  Future<List<ProductConfig>> cachedProducts() async {
    final rows = await (database.select(
      database.localProducts,
    )..where((row) => row.isActive.equals(true))).get();
    return rows
        .map(
          (row) => ProductConfig.fromJson(
            jsonDecode(row.payloadJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<DynamicFieldConfig>> cachedFields({
    String entityType = 'product',
  }) async {
    final rows =
        await (database.select(database.localDynamicFields)
              ..where(
                (row) =>
                    row.entityType.equals(entityType) &
                    row.visibleInFlutter.equals(true),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
            .get();

    return rows
        .map(
          (row) => DynamicFieldConfig.fromJson(
            jsonDecode(row.payloadJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> activatePayload(Map<String, dynamic> payload) async {
    await _cacheBatches(payload);
    await database.transaction(() async {
      await _purgeDemoData();
      await database.delete(database.localProducts).go();
      await database.delete(database.localProductVariants).go();
      await database.delete(database.localDynamicFields).go();

      final products = (payload['products'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      for (final product in products) {
        final productId = product['id']?.toString() ?? '';
        if (productId.isEmpty) {
          continue;
        }
        final productName = product['name']?.toString().trim();
        final productCode = _requiredCode(
          product['product_code'],
          fallbackSource: productName?.isNotEmpty == true
              ? productName!
              : productId,
        );
        await database
            .into(database.localProducts)
            .insert(
              LocalProductsCompanion.insert(
                id: productId,
                name: productName?.isNotEmpty == true
                    ? productName!
                    : 'Product',
                productCode: productCode,
                sku: Value(product['sku'] as String?),
                payloadJson: jsonEncode(product),
                isActive: Value(_asBool(product['is_active'], fallback: true)),
                configurationVersion: Value(
                  _asInt(product['configuration_version'], fallback: 1),
                ),
              ),
            );

        for (final variant
            in (product['variants'] as List<dynamic>? ?? const [])) {
          final variantJson = variant as Map<String, dynamic>;
          final variantId = variantJson['id']?.toString() ?? '';
          if (variantId.isEmpty) {
            continue;
          }
          final variantName = variantJson['name']?.toString().trim();
          await database
              .into(database.localProductVariants)
              .insert(
                LocalProductVariantsCompanion.insert(
                  id: variantId,
                  productId: productId,
                  name: variantName?.isNotEmpty == true
                      ? variantName!
                      : 'Detail',
                  variantCode: _requiredCode(
                    variantJson['variant_code'],
                    fallbackSource: variantName?.isNotEmpty == true
                        ? variantName!
                        : variantId,
                  ),
                  payloadJson: jsonEncode(variantJson),
                  isActive: Value(
                    _asBool(variantJson['is_active'], fallback: true),
                  ),
                ),
              );
        }
      }

      for (final field
          in (payload['dynamicFields'] as List<dynamic>? ?? const [])) {
        final fieldJson = field as Map<String, dynamic>;
        await database
            .into(database.localDynamicFields)
            .insert(
              LocalDynamicFieldsCompanion.insert(
                id: fieldJson['id'] as String,
                entityType: fieldJson['entity_type'] as String,
                internalKey: fieldJson['internal_key'] as String,
                fieldLabel: fieldJson['field_label'] as String,
                dataType: fieldJson['data_type'] as String,
                payloadJson: jsonEncode(fieldJson),
                visibleInFlutter: Value(
                  _asBool(fieldJson['visible_in_flutter'], fallback: true),
                ),
                sortOrder: Value(_asInt(fieldJson['sort_order'])),
              ),
            );
      }

      await (database.delete(
        database.localConfigurationVersions,
      )..where((row) => row.scope.equals('products'))).go();
      await database
          .into(database.localConfigurationVersions)
          .insert(
            LocalConfigurationVersionsCompanion.insert(
              id: 'products',
              scope: 'products',
              version: _asInt(payload['configurationVersion'], fallback: 1),
              activatedAt: DateTime.now(),
            ),
          );
    });
  }

  Future<void> _purgeDemoData() async {
    await (database.delete(
      database.localProductionTransactions,
    )..where((row) => row.id.like('demo_%'))).go();
    await (database.delete(
      database.localInventoryLedger,
    )..where((row) => row.id.like('demo_%'))).go();
    await (database.delete(
      database.localDispatchItems,
    )..where((row) => row.id.like('demo_%'))).go();
    await (database.delete(
      database.localDispatches,
    )..where((row) => row.id.like('demo_%'))).go();
    await (database.delete(
      database.localCustomers,
    )..where((row) => row.id.like('demo_%'))).go();
    await (database.delete(
      database.localInwardSessions,
    )..where((row) => row.id.like('demo_%'))).go();
  }

  Future<void> sync({String? deviceId}) async {
    final client = apiClient;
    if (client == null) {
      return;
    }
    final response = await client.get(
      '/sync/products',
      query: _deviceQuery(deviceId),
    );
    final payload = response.data as Map<String, dynamic>;
    final directBatches = await _fetchDirectBatches(client);
    if (directBatches != null) {
      payload['batches'] = directBatches;
    }
    await activatePayload(payload);
  }

  Future<List<dynamic>?> _fetchDirectBatches(ApiClient client) async {
    for (final path in const ['/sync/batches', '/batches']) {
      try {
        final response = await client.get(path);
        final batches = _extractBatches(response.data);
        if (batches != null) return batches;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  List<dynamic>? _extractBatches(Object? data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['batches', 'data', 'items']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> cachedBatches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _batchCacheKey());
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cacheBatches(Map<String, dynamic> payload) async {
    if (!payload.containsKey('batches')) return;
    final batches = payload['batches'];
    if (batches is! List) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _batchCacheKey(), jsonEncode(batches));
  }

  Future<String> _batchCacheKey() async {
    final scope = await ApiSession.accountScope();
    return '$_cachedProductBatchesPrefix.$scope';
  }

  Map<String, dynamic> _deviceQuery(String? deviceId) {
    if (deviceId == null) {
      return const {};
    }

    return {'device_id': deviceId};
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

  static String _requiredCode(Object? value, {required String fallbackSource}) {
    final raw = value?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;

    final normalized = fallbackSource
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '')
        .toUpperCase();
    if (normalized.isEmpty) return 'PRD';
    return normalized.length >= 3
        ? normalized.substring(0, 3)
        : normalized.padRight(3, 'X');
  }
}
