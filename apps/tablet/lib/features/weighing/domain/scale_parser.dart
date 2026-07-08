import 'dart:convert';
import 'dart:math';

import 'scale_models.dart';

class ScalePacketBuffer {
  ScalePacketBuffer(this.profile);

  final ScaleParsingProfile profile;
  final StringBuffer _buffer = StringBuffer();

  List<String> addBytes(List<int> bytes) {
    final chunk = profile.encoding.toLowerCase() == 'utf8'
        ? utf8.decode(bytes, allowMalformed: true)
        : ascii.decode(bytes, allowInvalid: true);
    _buffer.write(chunk);
    final packets = <String>[];

    while (true) {
      var data = _buffer.toString();
      if (profile.startCharacter case final start?) {
        final startIndex = data.indexOf(start);
        if (startIndex < 0) {
          _buffer.clear();
          return packets;
        }
        if (startIndex > 0) {
          data = data.substring(startIndex);
          _buffer
            ..clear()
            ..write(data);
        }
      }

      if (profile.fixedLength case final length?) {
        if (data.length < length) return packets;
        packets.add(data.substring(0, length));
        _buffer
          ..clear()
          ..write(data.substring(length));
        continue;
      }

      final endIndex = data.indexOf(profile.endCharacter);
      if (endIndex < 0) return packets;
      packets.add(data.substring(0, endIndex + profile.endCharacter.length));
      _buffer
        ..clear()
        ..write(data.substring(endIndex + profile.endCharacter.length));
    }
  }
}

class ScaleReadingParser {
  const ScaleReadingParser(this.profile);

  final ScaleParsingProfile profile;

  ScaleReading? parse(String packet) {
    final raw = packet;
    var text = profile.trim ? packet.trim() : packet;
    if (profile.startCharacter != null &&
        text.startsWith(profile.startCharacter!)) {
      text = text.substring(profile.startCharacter!.length);
    }
    if (profile.prefixRemoval case final prefix?) {
      text = text.replaceFirst(prefix, '');
    }
    if (profile.suffixRemoval case final suffix?) {
      text = text.replaceFirst(suffix, '');
    }
    if (profile.endCharacter.isNotEmpty &&
        text.endsWith(profile.endCharacter.trim())) {
      text = text.substring(
        0,
        max(0, text.length - profile.endCharacter.trim().length),
      );
    }

    final stable =
        profile.stableTokens.any(text.contains) &&
        !profile.unstableTokens.any(text.contains);
    final weightText = _weightText(text);
    if (weightText == null) return null;
    final unit = _unit(text);
    final numeric = double.tryParse(
      weightText.replaceAll(RegExp('[^0-9+\\-.]'), ''),
    );
    if (numeric == null) return null;
    final value = profile.decimalPlaces == null
        ? numeric
        : numeric / pow(10, profile.decimalPlaces!).toDouble();

    return ScaleReading(
      grossWeight: value,
      unit: unit,
      isStable: stable,
      raw: raw,
      recordedAt: DateTime.now(),
    );
  }

  String? _weightText(String text) {
    if (profile.regex case final pattern?) {
      final expression = RegExp(pattern);
      final match = expression.firstMatch(text);
      if (match != null) {
        return match.groupCount >= 1 ? match.group(1) : match.group(0);
      }
    }

    if (profile.weightStart != null && profile.weightLength != null) {
      final start = profile.weightStart!;
      final end = min(text.length, start + profile.weightLength!);
      if (start >= text.length || start >= end) return null;
      return text.substring(start, end);
    }

    final match = RegExp(r'[+-]?\d+(?:\.\d+)?').firstMatch(text);
    return match?.group(0);
  }

  String _unit(String text) {
    for (final entry in profile.unitMapping.entries) {
      if (text.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return 'kg';
  }
}

class WeightStabilityDetector {
  WeightStabilityDetector({required this.duration, required this.tolerance});

  final Duration duration;
  final double tolerance;
  ScaleReading? _first;
  ScaleReading? _last;

  bool add(ScaleReading reading) {
    if (!reading.isStable) {
      _first = null;
      _last = reading;
      return false;
    }

    final first = _first;
    if (first == null ||
        (reading.grossWeight - first.grossWeight).abs() > tolerance) {
      _first = reading;
      _last = reading;
      return false;
    }

    _last = reading;
    return reading.recordedAt.difference(first.recordedAt) >= duration;
  }

  ScaleReading? get last => _last;
}
