class DeviceModel {
  final String plantName;
  final double temperature;
  final int moisture;
  final bool pump;
  final int lastSeen;
  final String mode;

  final int? autoMoistureDryBelow;
  final double? autoTemperatureMin;
  final double? autoTemperatureMax;

  final int? scheduleStartHour;
  final int? scheduleStartMinute;
  final int? scheduleEndHour;
  final int? scheduleEndMinute;

  DeviceModel({
    required this.plantName,
    required this.temperature,
    required this.moisture,
    required this.pump,
    required this.lastSeen,
    required this.mode,
    required this.autoMoistureDryBelow,
    required this.autoTemperatureMin,
    required this.autoTemperatureMax,
    required this.scheduleStartHour,
    required this.scheduleStartMinute,
    required this.scheduleEndHour,
    required this.scheduleEndMinute,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final sensor = Map<String, dynamic>.from(json['sensor_data'] ?? {});
    final control = Map<String, dynamic>.from(json['control_status'] ?? {});
    final auto = Map<String, dynamic>.from(control['auto_config'] ?? {});
    final schedule = Map<String, dynamic>.from(control['schedule'] ?? {});
    final lastSeenValue = json['last_seen'];

    return DeviceModel(
      plantName: json['plant_name'] ?? '-',

      temperature: (sensor['temperature'] ?? 0).toDouble(),
      moisture: (sensor['moisture'] ?? 0).toInt(),

      pump: control['pump'] ?? false,
      mode: (control['mode'] ?? 'manual').toString().toLowerCase(),

      lastSeen: lastSeenValue is num
          ? lastSeenValue.toInt()
          : int.tryParse('$lastSeenValue') ?? 0,

      autoMoistureDryBelow: auto['moistureDryBelow'],
      autoTemperatureMin: (auto['temperatureMin'])?.toDouble(),
      autoTemperatureMax: (auto['temperatureMax'])?.toDouble(),

      scheduleStartHour: schedule['startHour'],
      scheduleStartMinute: schedule['startMinute'],
      scheduleEndHour: schedule['endHour'],
      scheduleEndMinute: schedule['endMinute'],
    );
  }

  // ✅ TAMBAHAN PENTING
  bool get isOnline {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastSeen) < 60000;
  }
}
