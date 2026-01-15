import 'dart:io' show Platform;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef FolderCallback = void Function(String? path);

class SelFolder extends StatefulWidget {
  final FolderCallback? onFolderSelected;

  const SelFolder({this.onFolderSelected, super.key});

  @override
  State<SelFolder> createState() => _SelFolderState();
}

class _SelFolderState extends State<SelFolder> {
  static const _prefsKey = 'gensaku_app_folder';
  String? _folderPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKey);
    setState(() => _folderPath = path);
    widget.onFolderSelected?.call(path);
  }

  Future<void> _pickFolder() async {
    setState(() => _loading = true);
    try {
      // file_picker supports getDirectoryPath on desktop; on web it returns null / unsupported
      if (kIsWeb) {
        // Web cannot select a system folder. Show info dialog.
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Browser storage only'),
            content: const Text(
              'On web the app cannot access an arbitrary folder on your machine. '
              'Data will be stored in the browser (IndexedDB). If you want folder-based storage, use the desktop app.',
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
          ),
        );
      } else {
        // Use file_selector to pick a directory on desktop platforms
        final path = await getDirectoryPath();
        if (path != null && path.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, path);
          if (!mounted) return;
          setState(() => _folderPath = path);
          widget.onFolderSelected?.call(path);
        }
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Error selecting folder'),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    setState(() => _folderPath = null);
    widget.onFolderSelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _folderPath ?? (kIsWeb ? 'Using browser storage' : 'No folder selected'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_loading) const CircularProgressIndicator(strokeWidth: 2),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _pickFolder,
                  icon: const Icon(Icons.folder),
                  label: const Text('Select Folder'),
                ),
                if (_folderPath != null && !kIsWeb)
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                if (kIsWeb)
                  Tooltip(
                    message:
                        'Web apps store data inside your browser. To export or import, use the Sync options.',
                    child: const Icon(Icons.info_outline),
                  ),
              ],
            ),
            if (!kIsWeb && Platform.isWindows)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Selected folder will be used to store app data locally on your machine.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
