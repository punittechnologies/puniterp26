import 'dart:convert';

class ProductConfig {
  const ProductConfig({
    required this.id,
    required this.name,
    required this.productCode,
    required this.isActive,
    required this.effective,
    required this.variants,
    required this.raw,
  });

  factory ProductConfig.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Product';
    final code = json['product_code']?.toString().trim();

    return ProductConfig(
      id: id,
      name: name,
      productCode: code == null || code.isEmpty ? _codeFrom(name, id) : code,
      isActive: _asBool(json['is_active'], fallback: true),
      effective: EffectiveProductValues.fromJson(
        json['effective'] as Map<String, dynamic>? ?? const {},
      ),
      variants: ((json['variants'] as List<dynamic>? ?? const []))
          .map(
            (item) =>
                ProductVariantConfig.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      raw: json,
    );
  }

  final String id;
  final String name;
  final String productCode;
  final bool isActive;
  final EffectiveProductValues effective;
  final List<ProductVariantConfig> variants;
  final Map<String, dynamic> raw;
}

class ProductVariantConfig {
  const ProductVariantConfig({
    required this.id,
    required this.productId,
    required this.name,
    required this.variantCode,
    required this.effective,
    required this.raw,
  });

  factory ProductVariantConfig.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Detail';
    final code = json['variant_code']?.toString().trim();

    return ProductVariantConfig(
      id: id,
      productId: json['product_id']?.toString() ?? '',
      name: name,
      variantCode: code == null || code.isEmpty ? _codeFrom(name, id) : code,
      effective: EffectiveProductValues.fromJson(
        json['effective'] as Map<String, dynamic>? ?? const {},
      ),
      raw: json,
    );
  }

  final String id;
  final String productId;
  final String name;
  final String variantCode;
  final EffectiveProductValues effective;
  final Map<String, dynamic> raw;
}

String _codeFrom(String name, String id) {
  final normalized = name
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '')
      .toUpperCase();
  if (normalized.isNotEmpty) {
    return normalized.length >= 3
        ? normalized.substring(0, 3)
        : normalized.padRight(3, 'X');
  }

  final compactId = id.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toUpperCase();
  if (compactId.isNotEmpty) {
    return compactId.length >= 3
        ? compactId.substring(0, 3)
        : compactId.padRight(3, 'X');
  }

  return 'PRD';
}

class EffectiveProductValues {
  const EffectiveProductValues({
    this.tareWeight = '0.000',
    this.minimumWeight,
    this.maximumWeight,
    this.targetWeight,
    this.conversionRule,
    this.productLockMode = 'none',
    this.variantLockMode = 'none',
  });

  factory EffectiveProductValues.fromJson(Map<String, dynamic> json) {
    return EffectiveProductValues(
      tareWeight: '${json['tare_weight'] ?? '0.000'}',
      minimumWeight: json['minimum_weight']?.toString(),
      maximumWeight: json['maximum_weight']?.toString(),
      targetWeight: json['target_weight']?.toString(),
      conversionRule: json['conversion_rule'] as Map<String, dynamic>?,
      productLockMode: json['product_lock_mode'] as String? ?? 'none',
      variantLockMode: json['variant_lock_mode'] as String? ?? 'none',
    );
  }

  final String tareWeight;
  final String? minimumWeight;
  final String? maximumWeight;
  final String? targetWeight;
  final Map<String, dynamic>? conversionRule;
  final String productLockMode;
  final String variantLockMode;
}

class DynamicFieldConfig {
  const DynamicFieldConfig({
    required this.id,
    required this.entityType,
    required this.internalKey,
    required this.fieldLabel,
    required this.dataType,
    required this.required,
    required this.editable,
    required this.options,
  });

  factory DynamicFieldConfig.fromJson(Map<String, dynamic> json) {
    return DynamicFieldConfig(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      internalKey: json['internal_key'] as String,
      fieldLabel: json['field_label'] as String,
      dataType: json['data_type'] as String,
      required: _asBool(json['is_required']),
      editable: _asBool(json['editable_in_flutter'], fallback: true),
      options: _options(json['dropdown_options']),
    );
  }

  final String id;
  final String entityType;
  final String internalKey;
  final String fieldLabel;
  final String dataType;
  final bool required;
  final bool editable;
  final List<Map<String, dynamic>> options;
}

List<Map<String, dynamic>> _options(Object? raw) {
  if (raw == null) return const [];

  Object? parsed = raw;
  if (raw is String) {
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      parsed = null;
    }
  }

  if (parsed is! List) return const [];

  return parsed
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry('$key', value)))
      .toList();
}

bool _asBool(Object? value, {bool fallback = false}) {
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
