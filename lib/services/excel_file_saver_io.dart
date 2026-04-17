import 'dart:io';

Future<String> saveExcelFile(List<int> bytes, String filename) async {
  Directory directory;

  if (Platform.isAndroid) {
    final downloadDir = Directory('/storage/emulated/0/Download');
    directory = await downloadDir.exists() ? downloadDir : Directory.systemTemp;
  } else {
    directory = Directory.systemTemp;
  }

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
