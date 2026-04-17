import 'dart:convert';

import '../models/log_model.dart';
import 'excel_file_saver.dart';

class ExcelExportService {
  static String buildLogsExcelXml(List<LogModel> logs) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
        'xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:x="urn:schemas-microsoft-com:office:excel" '
        'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
      )
      ..writeln('<Worksheet ss:Name="Riwayat Penyiraman">')
      ..writeln('<Table>')
      ..writeln(
        _row([
          'Mulai',
          'Selesai',
          'Durasi (detik)',
          'Mode',
          'Moisture Awal (%)',
          'Moisture Akhir (%)',
          'Suhu Awal (C)',
          'Suhu Akhir (C)',
          'Catatan',
        ]),
      )
      ..writeAll(
        logs.map((log) {
          final startTime = DateTime.fromMillisecondsSinceEpoch(
            log.timestamp,
          ).toLocal();
          final endTime = log.endedAt == null
              ? ''
              : DateTime.fromMillisecondsSinceEpoch(log.endedAt!).toLocal()
                    .toString();
          final durationSeconds = log.durationMs == null
              ? ''
              : (log.durationMs! / 1000).toStringAsFixed(0);
          return _row([
            startTime.toString(),
            endTime,
            durationSeconds,
            log.type,
            '${log.startMoisture ?? ''}',
            '${log.endMoisture ?? ''}',
            log.startTemperature?.toStringAsFixed(1) ?? '',
            log.endTemperature?.toStringAsFixed(1) ?? '',
            log.reason ?? '',
          ]);
        }),
      )
      ..writeln('</Table>')
      ..writeln('</Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

  static Future<String> exportLogsToExcel(
    List<LogModel> logs, {
    required String deviceId,
  }) async {
    final safeDeviceId = deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename =
        'riwayat_penyiraman_${safeDeviceId}_$timestamp.xls';

    final content = buildLogsExcelXml(logs);
    final bytes = utf8.encode(content);

    return saveExcelFile(bytes, filename);
  }

  static String _row(List<String> values) {
    final cells = values
        .map(
          (value) =>
              '<Cell><Data ss:Type="String">${_escape(value)}</Data></Cell>',
        )
        .join();
    return '<Row>$cells</Row>';
  }

  static String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
