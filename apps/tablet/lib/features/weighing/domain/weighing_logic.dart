import '../../products/domain/conversion_calculator.dart';
import '../../products/domain/product_models.dart';
import 'scale_models.dart';
import 'scale_parser.dart';

enum WeightRangeStatus { underweight, accepted, overweight, noRule }

class WeightComputation {
  const WeightComputation({
    required this.gross,
    required this.tare,
    required this.net,
    required this.unit,
    required this.rangeStatus,
    this.actualPieces,
    this.roundedPieces,
  });

  final double gross;
  final double tare;
  final double net;
  final String unit;
  final WeightRangeStatus rangeStatus;
  final String? actualPieces;
  final String? roundedPieces;
}

class WeightRuleResolver {
  EffectiveProductValues resolve(
    ProductConfig? product,
    ProductVariantConfig? variant,
  ) {
    return variant?.effective ??
        product?.effective ??
        const EffectiveProductValues();
  }
}

class UnitConversionCalculator {
  const UnitConversionCalculator();

  Map<String, String>? calculate(double netWeight, Map<String, dynamic>? rule) {
    if (rule == null || rule.isEmpty) return null;
    return ConversionCalculator().calculate(netWeight: netWeight, rule: rule);
  }
}

class WeighingSession {
  WeighingSession({
    this.stabilityDuration = const Duration(milliseconds: 800),
    this.stabilityTolerance = 0.02,
    this.resetThreshold = 0.05,
  }) : _stability = WeightStabilityDetector(
         duration: stabilityDuration,
         tolerance: stabilityTolerance,
       );

  final Duration stabilityDuration;
  final double stabilityTolerance;
  final double resetThreshold;
  final WeightStabilityDetector _stability;
  CaptureState state = CaptureState.idle;
  double? _lastCapturedWeight;

  bool update(ScaleReading reading, WeightComputation computation) {
    if (computation.gross <= resetThreshold) {
      state = CaptureState.idle;
      _lastCapturedWeight = null;
      return false;
    }

    state = CaptureState.weightDetected;
    final stable = _stability.add(reading);
    if (!stable) {
      state = CaptureState.stabilising;
      return false;
    }

    state = CaptureState.stable;
    if (computation.rangeStatus == WeightRangeStatus.underweight ||
        computation.rangeStatus == WeightRangeStatus.overweight) {
      state = CaptureState.validated;
      return false;
    }

    final duplicate =
        _lastCapturedWeight != null &&
        (computation.net - _lastCapturedWeight!).abs() <= stabilityTolerance;
    state = duplicate
        ? CaptureState.waitingForItemRemoval
        : CaptureState.readyToCapture;
    return !duplicate;
  }

  void markCaptured(double netWeight) {
    _lastCapturedWeight = netWeight;
    state = CaptureState.saved;
  }
}

class WeighingController {
  WeighingController({
    required this.ruleResolver,
    required this.conversionCalculator,
  });

  final WeightRuleResolver ruleResolver;
  final UnitConversionCalculator conversionCalculator;

  WeightComputation compute({
    required ScaleReading reading,
    required ProductConfig? product,
    required ProductVariantConfig? variant,
    double? manualTare,
  }) {
    final effective = ruleResolver.resolve(product, variant);
    final gross = reading.grossWeight < 0 ? 0.0 : reading.grossWeight;
    final tare = manualTare ?? double.tryParse(effective.tareWeight) ?? 0;
    final net = (gross - tare).clamp(0, double.infinity).toDouble();
    final min = double.tryParse(effective.minimumWeight ?? '');
    final max = double.tryParse(effective.maximumWeight ?? '');
    final range = _range(net, min, max);
    final pieces = conversionCalculator.calculate(
      net,
      effective.conversionRule,
    );

    return WeightComputation(
      gross: gross,
      tare: tare,
      net: net,
      unit: reading.unit,
      rangeStatus: range,
      actualPieces: pieces?['actual_quantity'],
      roundedPieces: pieces?['rounded_quantity'],
    );
  }

  WeightRangeStatus _range(double net, double? min, double? max) {
    if (min == null && max == null) return WeightRangeStatus.noRule;
    if (min != null && net < min) return WeightRangeStatus.underweight;
    if (max != null && net > max) return WeightRangeStatus.overweight;
    return WeightRangeStatus.accepted;
  }
}
