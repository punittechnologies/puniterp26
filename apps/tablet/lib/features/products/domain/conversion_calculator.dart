import 'dart:math';

class ConversionCalculator {
  Map<String, String> calculate({
    required double netWeight,
    required Map<String, dynamic> rule,
  }) {
    final actual = switch (rule['method'] as String) {
      'weight_per_piece' =>
        netWeight / _requiredDouble(rule, 'weight_per_piece'),
      'pieces_per_kg' => netWeight * _requiredDouble(rule, 'pieces_per_kg'),
      'sample_based' =>
        netWeight /
            (_requiredDouble(rule, 'sample_weight') /
                _requiredInt(rule, 'sample_piece_count')),
      _ => throw ArgumentError('Unsupported conversion method'),
    };
    final places = rule['decimal_places'] as int? ?? 0;

    return {
      'actual_quantity': actual.toStringAsFixed(6),
      'rounded_quantity': _round(
        actual,
        rule['rounding_method'] as String? ?? 'none',
        places,
      ).toStringAsFixed(places),
    };
  }

  double _round(double value, String method, int places) {
    final factor = pow(10, places).toDouble();
    return switch (method) {
      'nearest' => (value * factor).round() / factor,
      'floor' => (value * factor).floor() / factor,
      'ceil' => (value * factor).ceil() / factor,
      _ => value,
    };
  }

  double _requiredDouble(Map<String, dynamic> rule, String key) {
    final value = double.tryParse('${rule[key]}');
    if (value == null || value <= 0) {
      throw ArgumentError('$key must be greater than zero');
    }
    return value;
  }

  int _requiredInt(Map<String, dynamic> rule, String key) {
    final value = int.tryParse('${rule[key]}');
    if (value == null || value <= 0) {
      throw ArgumentError('$key must be greater than zero');
    }
    return value;
  }
}
