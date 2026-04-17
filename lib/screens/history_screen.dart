import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../models/log_model.dart';
import '../services/excel_export_service.dart';
import '../services/firebase_service.dart';
import '../widgets/history_chart.dart';

enum HistoryFilter { all, daily, weekly }

class HistoryScreen extends StatefulWidget {
  final String deviceId;

  const HistoryScreen({super.key, required this.deviceId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<LogModel> logs = [];
  bool isLoading = true;
  HistoryFilter _selectedFilter = HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    final deviceHistoryRef = FirebaseDatabase.instance
        .ref('devices/${widget.deviceId}/history')
        .limitToLast(50);
    final legacyHistoryRef = FirebaseDatabase.instance
        .ref('history')
        .limitToLast(50);

    var snapshot = await deviceHistoryRef.get();

    // Backward compatibility: beberapa data lama tersimpan di root /history.
    if (!snapshot.exists) {
      snapshot = await legacyHistoryRef.get();
    }

    if (!snapshot.exists) {
      setState(() {
        logs = [];
        isLoading = false;
      });
      return;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    final fetched = data.entries
        .map((e) => LogModel.fromJson(Map<String, dynamic>.from(e.value)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      logs = fetched;
      isLoading = false;
    });
  }

  Future<void> exportExcel() async {
    await ExcelExportService.exportLogsToExcel(
      _filteredLogs,
      deviceId: widget.deviceId,
    );
  }

  Future<void> resetHistory() async {
    await FirebaseService.clearHistory(widget.deviceId);
    await fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: filteredLogs.isEmpty ? null : exportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: logs.isEmpty ? null : resetHistory,
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('Belum ada data'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilterBar(),
                const SizedBox(height: 16),
                if (filteredLogs.isEmpty)
                  _buildEmptyFilteredState()
                else
                  HistoryChart(logs: filteredLogs),
                const SizedBox(height: 16),
                Text(
                  'Daftar Riwayat Penyiraman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (filteredLogs.isEmpty)
                  const Text(
                    'Tidak ada riwayat penyiraman pada rentang waktu ini.',
                    style: TextStyle(color: Color(0xFF667561)),
                  ),
                ...filteredLogs.map((log) {
                  final moistureDelta =
                      (log.endMoisture ?? 0) - (log.startMoisture ?? 0);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        foregroundColor: const Color(0xFF2E7D32),
                        child: const Icon(Icons.water_drop_outlined),
                      ),
                      title: Text('Mode: ${log.type}'),
                      subtitle: Text(
                        'Mulai: ${_format(log.timestamp)}\n'
                        'Durasi: ${_duration(log.durationMs)}\n'
                        'Moisture: ${log.startMoisture} -> ${log.endMoisture}\n'
                        'Kenaikan: ${moistureDelta >= 0 ? '+' : ''}$moistureDelta%',
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  List<LogModel> get _filteredLogs {
    if (_selectedFilter == HistoryFilter.all) {
      return logs;
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(
      Duration(days: startOfToday.weekday - 1),
    );
    final threshold = _selectedFilter == HistoryFilter.daily
        ? startOfToday
        : startOfWeek;

    return logs.where((log) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
      return !timestamp.isBefore(threshold);
    }).toList();
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SegmentedButton<HistoryFilter>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF2E7D32);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF486046);
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700),
          ),
          side: WidgetStateProperty.all(BorderSide.none),
        ),
        segments: const [
          ButtonSegment(
            value: HistoryFilter.all,
            label: Text('Semua'),
            icon: Icon(Icons.history_outlined),
          ),
          ButtonSegment(
            value: HistoryFilter.daily,
            label: Text('Harian'),
            icon: Icon(Icons.today_outlined),
          ),
          ButtonSegment(
            value: HistoryFilter.weekly,
            label: Text('Mingguan'),
            icon: Icon(Icons.date_range_outlined),
          ),
        ],
        selected: {_selectedFilter},
        onSelectionChanged: (selection) {
          setState(() {
            _selectedFilter = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCF5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Riwayat Penyiraman',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == HistoryFilter.daily
                ? 'Belum ada sesi penyiraman hari ini.'
                : _selectedFilter == HistoryFilter.weekly
                    ? 'Belum ada sesi penyiraman minggu ini.'
                    : 'Belum ada sesi penyiraman yang tersimpan.',
            style: const TextStyle(color: Color(0xFF667561)),
          ),
        ],
      ),
    );
  }

  String _format(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month} $hour:$minute';
  }

  String _duration(int? ms) {
    if (ms == null) return '-';
    return '${(ms / 1000).toInt()} detik';
  }
}
