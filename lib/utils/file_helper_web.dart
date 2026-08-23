import 'dart:html' as html;

class FileHelper {
  static Future<void> saveAndShare(List<int> bytes, String fileName, String text) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
