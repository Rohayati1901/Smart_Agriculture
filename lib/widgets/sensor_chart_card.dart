import 'dart:math' as math;

import 'package:flutter/material.dart';

class SensorChartPoint {
  final DateTime time;
  final double temperature;
  final double moisture;

  const SensorChartPoint({
    required this.time,
    required this.temperature,
    required this.moisture,
  });
}

class SensorChartCard extends StatelessWidget {
  final List<SensorChartPoint> points;

  const SensorChartCard({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final latest = points.isNotEmpty ? points.last : null;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9FCF5), Color(0xFFFFFFFF)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grafik sensor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latest == null
                            ? 'Menunggu pembacaan sensor realtime'
                            : 'Monitoring realtime ${points.length} pembacaan terakhir',
                        style: const TextStyle(
                          color: Color(0xFF667561),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    latest == null
                        ? '-'
                        : '${_formatTime(latest.time)} WIB',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricBadge(
                  color: const Color(0xFF2E7D32),
                  label: 'Status',
                  value: latest == null ? 'Offline' : 'Realtime aktif',
                ),
                _MetricBadge(
                  color: const Color(0xFFD96C1D),
                  label: 'Suhu',
                  value: latest == null
                      ? '-'
                      : '${latest.temperature.toStringAsFixed(1)} C',
                ),
                _MetricBadge(
                  color: const Color(0xFF1E88E5),
                  label: 'Kelembapan',
                  value: latest == null
                      ? '-'
                      : '${latest.moisture.toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ChartSection(
              title: 'Suhu (C)',
              color: const Color(0xFFD96C1D),
              points: points,
              selector: (point) => point.temperature,
            ),
            const SizedBox(height: 18),
            _ChartSection(
              title: 'Kelembapan Tanah (%)',
              color: const Color(0xFF1E88E5),
              points: points,
              selector: (point) => point.moisture,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<SensorChartPoint> points;
  final double Function(SensorChartPoint point) selector;

  const _ChartSection({
    required this.title,
    required this.color,
    required this.points,
    required this.selector,
  });

  @override
  Widget build(BuildContext context) {
    final values = points.map(selector).toList(growable: false);
    final latestValue = values.isNotEmpty ? values.last : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              latestValue == null ? '-' : latestValue.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 150,
            color: const Color(0xFFF4F7F1),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: values.length < 2
                ? const Center(
                    child: Text(
                      'Grafik akan muncul setelah ada minimal 2 data',
                      style: TextStyle(color: Color(0xFF6B7767)),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: _LineChartPainter(
                            values: values,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            SensorChartCard._formatTime(points.first.time),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7767),
                            ),
                          ),
                          Text(
                            SensorChartCard._formatTime(points.last.time),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7767),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _MetricBadge({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5F6E5C),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _LineChartPainter({
    required this.values,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const verticalPadding = 12.0;
    const horizontalPadding = 6.0;
    final chartWidth = size.width - (horizontalPadding * 2);
    final chartHeight = size.height - (verticalPadding * 2);

    final gridPaint = Paint()
      ..color = const Color(0xFFDDE5D8)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = verticalPadding + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1.0);

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final dx = horizontalPadding +
          (chartWidth * i / math.max(values.length - 1, 1));
      final normalized = (values[i] - minValue) / range;
      final dy = verticalPadding + chartHeight - (normalized * chartHeight);
      final point = Offset(dx, dy);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, size.height - verticalPadding);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    final lastX = horizontalPadding + chartWidth;
    fillPath.lineTo(lastX, size.height - verticalPadding);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.26),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final lastPoint = _pointForIndex(values.length - 1, size, minValue, range);
    final pointPaint = Paint()..color = color;
    canvas.drawCircle(lastPoint, 4.5, pointPaint);
    canvas.drawCircle(
      lastPoint,
      8,
      Paint()..color = color.withValues(alpha: 0.16),
    );
  }

  Offset _pointForIndex(
    int index,
    Size size,
    double minValue,
    double range,
  ) {
    const verticalPadding = 12.0;
    const horizontalPadding = 6.0;
    final chartWidth = size.width - (horizontalPadding * 2);
    final chartHeight = size.height - (verticalPadding * 2);
    final dx = horizontalPadding +
        (chartWidth * index / math.max(values.length - 1, 1));
    final normalized = (values[index] - minValue) / range;
    final dy = verticalPadding + chartHeight - (normalized * chartHeight);
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
