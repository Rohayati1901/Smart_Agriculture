class LogModel {
  final int timestamp;
  final String type;
  final int? endedAt;
  final int? durationMs;
  final int? startMoisture;
  final int? endMoisture;
  final double? startTemperature;
  final double? endTemperature;
  final String? reason;

  LogModel({
    required this.timestamp,
    required this.type,
    this.endedAt,
    this.durationMs,
    this.startMoisture,
    this.endMoisture,
    this.startTemperature,
    this.endTemperature,
    this.reason,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    final timestampValue = json['timestamp'];
    final endedAtValue = json['endedAt'];
    final durationValue = json['durationMs'];

    return LogModel(
      timestamp: timestampValue is num
          ? timestampValue.toInt()
          : int.tryParse('$timestampValue') ?? 0,
      type: json['type'] ?? 'unknown',
      endedAt: endedAtValue is num
          ? endedAtValue.toInt()
          : int.tryParse('$endedAtValue'),
      durationMs: durationValue is num
          ? durationValue.toInt()
          : int.tryParse('$durationValue'),
      startMoisture: json['startMoisture'] is num
          ? (json['startMoisture'] as num).toInt()
          : int.tryParse('${json['startMoisture']}'),
      endMoisture: json['endMoisture'] is num
          ? (json['endMoisture'] as num).toInt()
          : int.tryParse('${json['endMoisture']}'),
      startTemperature: json['startTemperature'] is num
          ? (json['startTemperature'] as num).toDouble()
          : double.tryParse('${json['startTemperature']}'),
      endTemperature: json['endTemperature'] is num
          ? (json['endTemperature'] as num).toDouble()
          : double.tryParse('${json['endTemperature']}'),
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'type': type,
      if (endedAt != null) 'endedAt': endedAt,
      if (durationMs != null) 'durationMs': durationMs,
      if (startMoisture != null) 'startMoisture': startMoisture,
      if (endMoisture != null) 'endMoisture': endMoisture,
      if (startTemperature != null) 'startTemperature': startTemperature,
      if (endTemperature != null) 'endTemperature': endTemperature,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }
}
