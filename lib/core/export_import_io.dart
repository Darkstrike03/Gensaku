// Fallback for non-web platforms. For now, we throw unsupported.
Future<void> exportJsonWeb(String filename, String content) async {
  throw UnsupportedError('Export not implemented on this platform');
}

Future<String?> importJsonWeb() async {
  throw UnsupportedError('Import not implemented on this platform');
}
