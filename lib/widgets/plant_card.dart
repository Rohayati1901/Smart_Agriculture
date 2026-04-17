import 'package:flutter/material.dart';

import '../models/device_model.dart';

class PlantCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onEditName;

  const PlantCard({
    super.key,
    required this.device,
    this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9F7E7), Color(0xFFFFFFFF)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9F2DC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.local_florist_rounded,
                    color: Color(0xFF2E7D32),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanaman yang dipantau',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6A7A66),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.plantName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEditName != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEditName,
                    tooltip: 'Ubah nama tanaman',
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.thermostat_rounded,
                    title: 'Suhu',
                    value: '${device.temperature.toStringAsFixed(1)} C',
                    color: const Color(0xFFFFF3E0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.water_drop_outlined,
                    title: 'Kelembapan',
                    value: '${device.moisture}%',
                    color: const Color(0xFFE3F2FD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: device.isOnline
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    device.isOnline ? Icons.wifi : Icons.wifi_off,
                    color: device.isOnline
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFB3261E),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    device.isOnline
                        ? 'Perangkat sedang online'
                        : 'Perangkat sedang offline',
                    style: TextStyle(
                      color: device.isOnline
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB3261E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF335C2D)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF60705B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
