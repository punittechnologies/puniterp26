class WeightReading {
  const WeightReading({
    required this.grossWeight,
    required this.unit,
    required this.isStable,
    required this.rawPayload,
  });

  final String grossWeight;
  final String unit;
  final bool isStable;
  final String rawPayload;
}

abstract interface class ScaleAdapter {
  Future<List<String>> discover();
  Future<void> connect(String deviceIdentifier);
  Future<void> disconnect();
  Stream<WeightReading> readings();
  Future<void> zero();
  Future<void> tare();
}
