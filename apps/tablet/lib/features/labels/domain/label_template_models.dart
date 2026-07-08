class LabelTemplateConfig {
  const LabelTemplateConfig({
    required this.id,
    required this.name,
    required this.code,
    required this.scope,
    this.productId,
    this.variantId,
    required this.activeVersion,
    required this.isDefault,
    required this.templateJson,
  });

  factory LabelTemplateConfig.fromJson(Map<String, dynamic> json) {
    return LabelTemplateConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      scope: json['scope'] as String,
      productId: json['productId'] as String?,
      variantId: json['variantId'] as String?,
      activeVersion: json['activeVersion'] as int? ?? 1,
      isDefault: json['isDefault'] as bool? ?? false,
      templateJson: json['templateJson'] as Map<String, dynamic>? ?? const {},
    );
  }

  final String id;
  final String name;
  final String code;
  final String scope;
  final String? productId;
  final String? variantId;
  final int activeVersion;
  final bool isDefault;
  final Map<String, dynamic> templateJson;
}

class LabelElementConfig {
  const LabelElementConfig({
    required this.key,
    required this.type,
    this.bindingKey,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory LabelElementConfig.fromJson(Map<String, dynamic> json) {
    return LabelElementConfig(
      key: json['key'] as String,
      type: json['type'] as String,
      bindingKey: json['bindingKey'] as String?,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  final String key;
  final String type;
  final String? bindingKey;
  final double x;
  final double y;
  final double width;
  final double height;
}
