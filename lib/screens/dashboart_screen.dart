import 'package:flutter/material.dart';

import '../models/device_model.dart';
import '../screens/history_screen.dart';
import '../services/firebase_service.dart';
import '../widgets/plant_card.dart';
import '../widgets/pump_control.dart';

class DashboardScreen extends StatefulWidget {
  final String deviceId;

  const DashboardScreen({super.key, required this.deviceId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<DeviceModel> _deviceStream;
  final _plantNameController = TextEditingController();

  // ✅ DATA GRAFIK
  List<double> tempHistory = [];
  List<double> moistureHistory = [];

  @override
  void initState() {
    super.initState();
    _deviceStream = FirebaseService.streamDevice(widget.deviceId);
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    super.dispose();
  }

  Future<void> _togglePump(bool isOn) async {
    await FirebaseService.togglePump(widget.deviceId, !isOn);
  }

  Future<void> _changeMode(String mode) async {
    await FirebaseService.setMode(widget.deviceId, mode);
  }

  Future<void> _saveAutoConfig(
    int moistureDryBelow,
    double temperatureMin,
    double temperatureMax,
  ) async {
    await FirebaseService.setAutoConfig(
      widget.deviceId,
      moistureDryBelow: moistureDryBelow,
      temperatureMin: temperatureMin,
      temperatureMax: temperatureMax,
    );
  }

  Future<void> _changeSchedule(TimeOfDay? start, TimeOfDay? end) async {
    await FirebaseService.setSchedule(widget.deviceId, {
      'startHour': start?.hour ?? 0,
      'startMinute': start?.minute ?? 0,
      'endHour': end?.hour ?? 0,
      'endMinute': end?.minute ?? 0,
    });
  }

  Future<void> _editPlantName(String currentName) async {
    _plantNameController.text = currentName;

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Nama Tanaman'),
        content: TextField(controller: _plantNameController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, _plantNameController.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await FirebaseService.updatePlantName(widget.deviceId, newName);
    }
  }

  TimeOfDay? _timeFromParts(int? h, int? m) {
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HistoryScreen(deviceId: widget.deviceId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DeviceModel>(
        stream: _deviceStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final d = snapshot.data!;

          // ✅ UPDATE DATA GRAFIK
          tempHistory.add(d.temperature);
          moistureHistory.add(d.moisture.toDouble());

          if (tempHistory.length > 20) tempHistory.removeAt(0);
          if (moistureHistory.length > 20) moistureHistory.removeAt(0);

          final start =
              _timeFromParts(d.scheduleStartHour, d.scheduleStartMinute);
          final end =
              _timeFromParts(d.scheduleEndHour, d.scheduleEndMinute);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🌱 CARD TANAMAN
                PlantCard(
                  device: d,
                  onEditName: () => _editPlantName(d.plantName),
                ),

                const SizedBox(height: 16),

                // 🔌 CONTROL
                PumpControl(
                  isOn: d.pump,
                  mode: d.mode,
                  moisture: d.moisture,
                  temperature: d.temperature,
                  autoMoistureDryBelow: d.autoMoistureDryBelow,
                  autoTemperatureMin: d.autoTemperatureMin,
                  autoTemperatureMax: d.autoTemperatureMax,
                  scheduleStart: start,
                  scheduleEnd: end,
                  onToggle: () => _togglePump(d.pump),
                  onModeChanged: _changeMode,
                  onAutoConfigSaved: _saveAutoConfig,
                  onStartTimeChanged: (t) => _changeSchedule(t, end),
                  onEndTimeChanged: (t) => _changeSchedule(start, t),
                ),

                const SizedBox(height: 16),

                // 📊 GRAFIK SUHU
                LiveChart(
                  data: tempHistory,
                  title: "Suhu (°C)",
                  color: Colors.red,
                ),

                const SizedBox(height: 10),

                // 📊 GRAFIK KELEMBAPAN
                LiveChart(
                  data: moistureHistory,
                  title: "Kelembapan (%)",
                  color: Colors.blue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LiveChart extends StatelessWidget {
  final List<double> data;
  final String title;
  final Color color;

  const LiveChart({
    super.key,
    required this.data,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: data.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : CustomPaint(
                      painter: ChartPainter(data, color),
                      size: const Size(double.infinity, 120),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  ChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final maxValue = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 1;
    final minValue = data.isNotEmpty ? data.reduce((a, b) => a < b ? a : b) : 0;
    final range = maxValue - minValue > 0 ? maxValue - minValue : 1;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) => true;
}
