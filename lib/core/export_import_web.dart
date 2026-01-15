// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// Web implementation for export / import
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<void> exportJsonWeb(String filename, String content) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<String?> importJsonWeb() async {
  final input = html.FileUploadInputElement()..accept = '.json,application/json';
  input.click();
  final completer = Completer<String?>();
  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      completer.complete(reader.result as String?);
    });
    reader.onError.listen((e) {
      completer.completeError(e);
    });
    reader.readAsText(file);
  });
  return completer.future;
}
