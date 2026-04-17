import 'package:flutter/material.dart';

class PumpControl extends StatefulWidget {
  final bool isOn;
  final String mode;
  final int moisture;
  final double temperature;
  final int? autoMoistureDryBelow;
  final double? autoTemperatureMin;
  final double? autoTemperatureMax;
  final VoidCallback onToggle;
  final TimeOfDay? scheduleStart;
  final TimeOfDay? scheduleEnd;
  final void Function(TimeOfDay) onStartTimeChanged;
  final void Function(TimeOfDay) onEndTimeChanged;
  final void Function(String) onModeChanged;
  final void Function(int, double, double) onAutoConfigSaved;

  const PumpControl({
    super.key,
    required this.isOn,
    required this.mode,
    required this.moisture,
    required this.temperature,
    required this.autoMoistureDryBelow,
    required this.autoTemperatureMin,
    required this.autoTemperatureMax,
    required this.onToggle,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onModeChanged,
    required this.onAutoConfigSaved,
  });

  @override
  State<PumpControl> createState() => _PumpControlState();
}

class _PumpControlState extends State<PumpControl> {
  late final TextEditingController moistureController;
  late final TextEditingController tempMinController;
  late final TextEditingController tempMaxController;

  @override
  void initState() {
    super.initState();
    moistureController = TextEditingController();
    tempMinController = TextEditingController();
    tempMaxController = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant PumpControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoMoistureDryBelow != widget.autoMoistureDryBelow ||
        oldWidget.autoTemperatureMin != widget.autoTemperatureMin ||
        oldWidget.autoTemperatureMax != widget.autoTemperatureMax) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    moistureController.text = '${widget.autoMoistureDryBelow ?? 40}';
    tempMinController.text = '${widget.autoTemperatureMin ?? 24}';
    tempMaxController.text = '${widget.autoTemperatureMax ?? 32}';
  }

  @override
  void dispose() {
    moistureController.dispose();
    tempMinController.dispose();
    tempMaxController.dispose();
    super.dispose();
  }

  void _selectTime(
    BuildContext context,
    TimeOfDay? initialTime,
    void Function(TimeOfDay) onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (picked != null) onChanged(picked);
  }

  void _saveAutoConfig() {
    final moisture = int.tryParse(moistureController.text.trim());
    final tempMin = double.tryParse(tempMinController.text.trim());
    final tempMax = double.tryParse(tempMaxController.text.trim());

    if (moisture == null || tempMin == null || tempMax == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi angka yang valid untuk mode otomatis')),
      );
      return;
    }

    if (tempMin > tempMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suhu minimum tidak boleh lebih besar dari maksimum')),
      );
      return;
    }

    widget.onAutoConfigSaved(moisture, tempMin, tempMax);
  }

  bool get _isSoilDry {
    final limit = widget.autoMoistureDryBelow ?? 40;
    return widget.moisture < limit;
  }

  bool get _isTemperatureIdeal {
    final min = widget.autoTemperatureMin ?? 24;
    final max = widget.autoTemperatureMax ?? 32;
    return widget.temperature >= min && widget.temperature <= max;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 420;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kontrol Penyiraman',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih cara penyiraman yang ingin digunakan.',
              style: TextStyle(fontSize: 14, color: Color(0xFF5E6E5A)),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 12,
                    vertical: 10,
                  ),
                ),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              segments: [
                ButtonSegment<String>(
                  value: 'manual',
                  icon: Icon(Icons.toggle_on_outlined),
                  label: const _SegmentLabel('Manual'),
                ),
                ButtonSegment<String>(
                  value: 'auto',
                  icon: Icon(Icons.sensors_outlined),
                  label: _SegmentLabel(isCompact ? 'Auto' : 'Otomatis'),
                ),
                ButtonSegment<String>(
                  value: 'schedule',
                  icon: Icon(Icons.schedule),
                  label: _SegmentLabel(isCompact ? 'Jadwal' : 'Schedule'),
                ),
              ],
              selected: {widget.mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                widget.onModeChanged(selection.first);
              },
            ),
            const SizedBox(height: 18),
            if (widget.mode == 'manual') _buildManualCard(),
            if (widget.mode == 'auto') _buildAutoCard(),
            if (widget.mode == 'schedule') _buildScheduleCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isOn ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isOn ? 'Pompa sedang menyala' : 'Pompa sedang mati',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mode manual memakai tombol ON/OFF agar kamu bisa mengontrol pompa langsung.',
            style: TextStyle(fontSize: 14, color: Color(0xFF5E6E5A)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isOn ? null : widget.onToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  child: const Text('ON'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isOn ? widget.onToggle : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3261E),
                  ),
                  child: const Text('OFF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCard() {
    final dryText = _isSoilDry ? 'Tanah terdeteksi kering' : 'Tanah belum kering';
    final tempText = _isTemperatureIdeal
        ? 'Suhu ideal untuk menyiram'
        : 'Suhu belum ideal untuk menyiram';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mode otomatis berdasarkan sensor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pompa akan aktif saat soil moisture menunjukkan tanah kering dan suhu DHT berada pada rentang ideal.',
            style: TextStyle(fontSize: 14, color: Color(0xFF5E6E5A)),
          ),
          const SizedBox(height: 16),
          _StatusPill(
            label: dryText,
            active: _isSoilDry,
            activeColor: const Color(0xFFB3261E),
          ),
          const SizedBox(height: 10),
          _StatusPill(
            label: tempText,
            active: _isTemperatureIdeal,
            activeColor: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 16),
          _AutoField(
            title: 'Soil moisture dianggap kering jika dibawah',
            controller: moistureController,
            keyboardType: TextInputType.number,
            icon: Icons.water_drop_outlined,
            suffixText: '%',
          ),
          const SizedBox(height: 10),
          _AutoField(
            title: 'Suhu minimum ideal',
            controller: tempMinController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            icon: Icons.thermostat_outlined,
            suffixText: 'C',
          ),
          const SizedBox(height: 10),
          _AutoField(
            title: 'Suhu maksimum ideal',
            controller: tempMaxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            icon: Icons.device_thermostat,
            suffixText: 'C',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAutoConfig,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Aturan Otomatis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mode schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Atur jam mulai dan jam selesai penyiraman agar pompa berjalan sesuai waktu yang kamu tentukan.',
            style: TextStyle(fontSize: 14, color: Color(0xFF5E6E5A)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  label: 'Mulai',
                  value: widget.scheduleStart?.format(context) ?? '--:--',
                  onTap: () => _selectTime(
                    context,
                    widget.scheduleStart,
                    widget.onStartTimeChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeTile(
                  label: 'Selesai',
                  value: widget.scheduleEnd?.format(context) ?? '--:--',
                  onTap: () => _selectTime(
                    context,
                    widget.scheduleEnd,
                    widget.onEndTimeChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final String text;

  const _SegmentLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class _AutoField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData icon;
  final String suffixText;

  const _AutoField({
    required this.title,
    required this.controller,
    required this.keyboardType,
    required this.icon,
    required this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF234F1E),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;

  const _StatusPill({
    required this.label,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withValues(alpha: 0.12)
            : const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.info_outline,
            color: active ? activeColor : const Color(0xFF60705B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? activeColor : const Color(0xFF60705B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF60705B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
