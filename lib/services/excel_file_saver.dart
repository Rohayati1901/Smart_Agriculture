import 'excel_file_saver_io.dart'
    if (dart.library.html) 'excel_file_saver_web.dart' as saver;

Future<String> saveExcelFile(List<int> bytes, String filename) {
  return saver.saveExcelFile(bytes, filename);
}
