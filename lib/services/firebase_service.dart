import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart'; // ✅ WAJIB (buat debugPrint)

import '../models/device_model.dart';

class FirebaseService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// 🔗 Reference ke device
  static DatabaseReference deviceRef(String deviceId) {
    return _db.ref('devices/$deviceId');
  }

  /// 📡 STREAM DEVICE (REALTIME)
  static Stream<DeviceModel> streamDevice(String deviceId) {
    return deviceRef(deviceId).onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return DeviceModel.fromJson({});
      }

      return DeviceModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    });
  }

  /// 🌱 UPDATE NAMA TANAMAN
  static Future<void> updatePlantName(
    String deviceId,
    String name,
  ) async {
    await deviceRef(deviceId).child('plant_name').set(name);
  }

  /// 🔌 ON / OFF POMPA
  static Future<void> togglePump(
    String deviceId,
    bool status,
  ) async {
    await deviceRef(deviceId)
        .child('control_status/pump')
        .set(status);
  }

  /// ⚙️ GANTI MODE (manual / auto / schedule)
  static Future<void> setMode(
    String deviceId,
    String mode,
  ) async {
    await deviceRef(deviceId)
        .child('control_status/mode')
        .set(mode.toLowerCase()); // ✅ biar aman
  }

  /// 🤖 AUTO CONFIG
  static Future<void> setAutoConfig(
    String deviceId, {
    required int moistureDryBelow,
    required double temperatureMin,
    required double temperatureMax,
  }) async {
    await deviceRef(deviceId)
        .child('control_status/auto_config')
        .set({
      'moistureDryBelow': moistureDryBelow,
      'temperatureMin': temperatureMin,
      'temperatureMax': temperatureMax,
    });
  }

  /// ⏰ SCHEDULE
  static Future<void> setSchedule(
    String deviceId,
    Map<String, int> schedule,
  ) async {
    await deviceRef(deviceId)
        .child('control_status/schedule')
        .set(schedule);
  }

  /// 🧹 CLEAR HISTORY (SUDAH FIX)
  static Future<void> clearHistory(String deviceId) async {
    try {
      await deviceRef(deviceId).child('history').remove();
    } catch (e) {
      debugPrint('Error clear history: $e'); // ✅ aman
    }
  }
}