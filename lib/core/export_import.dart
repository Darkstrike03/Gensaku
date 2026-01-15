// Conditional import: use web implementation when available.
export 'export_import_io.dart' if (dart.library.html) 'export_import_web.dart';
