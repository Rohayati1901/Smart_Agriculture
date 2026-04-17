import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/log_model.dart';

class HistoryChart extends StatelessWidget {
  final List<LogModel> logs;

  const HistoryChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final chartLogs = logs.reversed.toList(growable: false);
    final durationSpots = chartLogs.asMap().entries.map((entry) {
      final durationSeconds = ((entry.value.durationMs ?? 0) / 1000).toDouble();
      return FlSpot(entry.key.toDouble(), durationSeconds);
    }).toList(growable: false);
    final moistureGainSpots = chartLogs.asMap().entries.map((entry) {
      final gain =
          ((entry.value.endMoisture ?? 0) - (entry.value.startMoisture ?? 0))
              .toDouble();
      return FlSpot(entry.key.toDouble(), gain);
    }).toList(growable: false);

    final totalDurationSeconds = chartLogs.fold<double>(
      0,
      (sum, log) => sum + ((log.durationMs ?? 0) / 1000),
    );
    final averageDurationSeconds = chartLogs.isEmpty
        ? 0.0
        : totalDurationSeconds / chartLogs.length;
    final averageMoistureGain = chartLogs.isEmpty
        ? 0.0
        : chartLogs
                .map((log) => (log.endMoisture ?? 0) - (log.startMoisture ?? 0))
                .reduce((a, b) => a + b) /
            chartLogs.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Riwayat Penyiraman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Memantau durasi penyiraman dan perubahan kelembapan tiap sesi.',
              style: TextStyle(color: Color(0xFF667561)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryChip(
                  label: 'Total sesi',
                  value: '${chartLogs.length}',
                  color: const Color(0xFF2E7D32),
                ),
                _SummaryChip(
                  label: 'Rata-rata durasi',
                  value: '${averageDurationSeconds.toStringAsFixed(0)} dtk',
                  color: const Color(0xFFD96C1D),
                ),
                _SummaryChip(
                  label: 'Rata-rata kenaikan',
                  value: '${averageMoistureGain.toStringAsFixed(1)}%',
                  color: const Color(0xFF1E88E5),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: chartLogs.isEmpty ? 0 : (chartLogs.length - 1).toDouble(),
                  minY: _minY(durationSpots, moistureGainSpots),
                  maxY: _maxY(durationSpots, moistureGainSpots),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _interval(durationSpots, moistureGainSpots),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide.none,
                      top: BorderSide.none,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: _interval(durationSpots, moistureGainSpots),
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7767),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= chartLogs.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7767),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final log = chartLogs[spot.x.toInt()];
                          final label = spot.barIndex == 0
                              ? 'Durasi'
                              : 'Naik moisture';
                          final suffix = spot.barIndex == 0 ? ' dtk' : '%';
                          return LineTooltipItem(
                            '$label\n${spot.y.toStringAsFixed(1)}$suffix\n${_formatDate(log.timestamp)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: durationSpots,
                      isCurved: true,
                      color: const Color(0xFF2E7D32),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      ),
                    ),
                    LineChartBarData(
                      spots: moistureGainSpots,
                      isCurved: true,
                      color: const Color(0xFF1E88E5),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendItem(
                  color: Color(0xFF2E7D32),
                  label: 'Durasi penyiraman (detik)',
                ),
                _LegendItem(
                  color: Color(0xFF1E88E5),
                  label: 'Kenaikan moisture (%)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _minY(List<FlSpot> durationSpots, List<FlSpot> moistureGainSpots) {
    final values = [
      ...durationSpots.map((e) => e.y),
      ...moistureGainSpots.map((e) => e.y),
    ];
    if (values.isEmpty) return 0;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    return minValue > 0 ? 0 : minValue - 2;
  }

  double _maxY(List<FlSpot> durationSpots, List<FlSpot> moistureGainSpots) {
    final values = [
      ...durationSpots.map((e) => e.y),
      ...moistureGainSpots.map((e) => e.y),
    ];
    if (values.isEmpty) return 10;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue + 2;
  }

  double _interval(List<FlSpot> durationSpots, List<FlSpot> moistureGainSpots) {
    final maxValue = _maxY(durationSpots, moistureGainSpots);
    return maxValue <= 10 ? 2 : (maxValue / 4).ceilToDouble();
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5F6E5C)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5F6E5C)),
        ),
      ],
    );
  }
}
