import 'dart:convert';

enum ScaleConnectionStatus {
  disabled,
  permissionRequired,
  disconnected,
  discovering,
  connecting,
  connected,
  receiving,
  reconnecting,
  error,
  failed,
}

enum ScaleTransportType { classicSpp, bleGatt, simulator }

class ScaleDevice {
  const ScaleDevice({
    required this.id,
    required this.name,
    required this.transportType,
    this.address,
    this.isPaired = false,
    this.rssi,
  });

  factory ScaleDevice.fromJson(Map<String, dynamic> json) {
    return ScaleDevice(
      id: json['id']?.toString() ?? json['address']?.toString() ?? '',
      name: json['name']?.toString() ?? json['address']?.toString() ?? 'Scale',
      transportType: ScaleTransportType.values.firstWhere(
        (type) => type.name == json['transportType'],
        orElse: () => ScaleTransportType.classicSpp,
      ),
      address: json['address']?.toString(),
      isPaired: json['isPaired'] as bool? ?? false,
      rssi: json['rssi'] as int?,
    );
  }

  final String id;
  final String name;
  final ScaleTransportType transportType;
  final String? address;
  final bool isPaired;
  final int? rssi;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'transportType': transportType.name,
    'address': address,
    'isPaired': isPaired,
    'rssi': rssi,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScaleDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum CaptureState {
  idle,
  weightDetected,
  stabilising,
  stable,
  validated,
  readyToCapture,
  saving,
  saved,
  waitingForItemRemoval,
}

class ScaleReading {
  const ScaleReading({
    required this.grossWeight,
    required this.unit,
    required this.isStable,
    required this.raw,
    required this.recordedAt,
    this.stabilitySignalPresent = true,
    this.deviceId,
    this.profileId,
  });

  final double grossWeight;
  final String unit;
  final bool isStable;
  final String raw;
  final DateTime recordedAt;
  final bool stabilitySignalPresent;
  final String? deviceId;
  final String? profileId;

  bool get isStale =>
      DateTime.now().difference(recordedAt) > const Duration(seconds: 3);

  Map<String, dynamic> toJson() => {
    'grossWeight': grossWeight,
    'unit': unit,
    'isStable': isStable,
    'stabilitySignalPresent': stabilitySignalPresent,
    'raw': raw,
    'recordedAt': recordedAt.toIso8601String(),
    'deviceId': deviceId,
    'profileId': profileId,
  };
}

class ScaleParsingProfile {
  const ScaleParsingProfile({
    required this.id,
    required this.name,
    this.startCharacter,
    this.endCharacter = '\n',
    this.delimiter,
    this.fixedLength,
    this.weightStart,
    this.weightLength,
    this.decimalPlaces,
    this.prefixRemoval,
    this.suffixRemoval,
    this.regex,
    this.stableTokens = const ['ST', 'S'],
    this.unstableTokens = const ['US', 'U'],
    this.unitMapping = const {'kg': 'kg', 'g': 'g', 'lb': 'lb'},
    this.encoding = 'ascii',
    this.trim = true,
    this.exampleRaw = 'ST,GS,+0012.340kg',
  });

  factory ScaleParsingProfile.fromJson(Map<String, dynamic> json) {
    return ScaleParsingProfile(
      id: json['id']?.toString() ?? 'default',
      name: json['name']?.toString() ?? 'Default',
      startCharacter: json['startCharacter'] as String?,
      endCharacter: json['endCharacter'] as String? ?? '\n',
      delimiter: json['delimiter'] as String?,
      fixedLength: json['fixedLength'] as int?,
      weightStart: json['weightStart'] as int?,
      weightLength: json['weightLength'] as int?,
      decimalPlaces: json['decimalPlaces'] as int?,
      prefixRemoval: json['prefixRemoval'] as String?,
      suffixRemoval: json['suffixRemoval'] as String?,
      regex: json['regex'] as String?,
      stableTokens:
          (json['stableTokens'] as List<dynamic>? ?? const ['ST', 'S'])
              .map((e) => e.toString())
              .toList(),
      unstableTokens:
          (json['unstableTokens'] as List<dynamic>? ?? const ['US', 'U'])
              .map((e) => e.toString())
              .toList(),
      unitMapping:
          (json['unitMapping'] as Map<String, dynamic>? ??
                  const {'kg': 'kg', 'g': 'g', 'lb': 'lb'})
              .map((key, value) => MapEntry(key, value.toString())),
      encoding: json['encoding']?.toString() ?? 'ascii',
      trim: json['trim'] as bool? ?? true,
      exampleRaw: json['exampleRaw']?.toString() ?? 'ST,GS,+0012.340kg',
    );
  }

  final String id;
  final String name;
  final String? startCharacter;
  final String endCharacter;
  final String? delimiter;
  final int? fixedLength;
  final int? weightStart;
  final int? weightLength;
  final int? decimalPlaces;
  final String? prefixRemoval;
  final String? suffixRemoval;
  final String? regex;
  final List<String> stableTokens;
  final List<String> unstableTokens;
  final Map<String, String> unitMapping;
  final String encoding;
  final bool trim;
  final String exampleRaw;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startCharacter': startCharacter,
    'endCharacter': endCharacter,
    'delimiter': delimiter,
    'fixedLength': fixedLength,
    'weightStart': weightStart,
    'weightLength': weightLength,
    'decimalPlaces': decimalPlaces,
    'prefixRemoval': prefixRemoval,
    'suffixRemoval': suffixRemoval,
    'regex': regex,
    'stableTokens': stableTokens,
    'unstableTokens': unstableTokens,
    'unitMapping': unitMapping,
    'encoding': encoding,
    'trim': trim,
    'exampleRaw': exampleRaw,
  };

  String encode() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScaleParsingProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

abstract interface class ScaleAdapter {
  Stream<ScaleReading> get readings;
  ScaleConnectionStatus get status;
  Future<void> connect();
  Future<void> disconnect();
  Future<List<String>> discoverDevices();
  Future<void> zero();
  Future<void> tare();
}

abstract interface class BluetoothTransport {
  Stream<List<int>> get byteStream;
  Stream<ScaleConnectionStatus> get statusStream;
  Stream<String> get rawDataStream;
  ScaleConnectionStatus get status;
  Future<bool> isEnabled();
  Future<bool> requestEnable();
  Future<List<ScaleDevice>> pairedDevices();
  Future<List<ScaleDevice>> scanDevices({Duration timeout});
  Future<List<String>> discoverDevices();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
}
