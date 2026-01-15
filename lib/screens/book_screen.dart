// dart:convert not required here

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gensaku/core/export_import.dart' as export_import;
import 'package:gensaku/widgets/navigationpanel.dart';
import 'package:gensaku/widgets/sidebar.dart';
import 'package:gensaku/models/chapter.dart';
import 'package:gensaku/widgets/chaptermodal.dart';
import 'package:gensaku/screens/chapter_editor.dart';
import 'package:gensaku/widgets/book.dart' as book_widget;

class BookScreen extends StatefulWidget {
  final book_widget.Book book;

  const BookScreen({required this.book, super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late List<Chapter> _chapters;
  late SharedPreferences _prefs;
  // no scaffold key needed; use Scaffold.of(context) when opening drawer

  String get _key => 'gensaku_chapters_${widget.book.id}';

  @override
  void initState() {
    super.initState();
    _chapters = [];
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    setState(() => _chapters = Chapter.listFromJson(raw));
  }

  List<String> get _exportedNames => _prefs.getStringList('gensaku_exported_names') ?? <String>[];

  Future<void> _saveExportName(String name) async {
    final list = _exportedNames.toList();
    if (!list.contains(name)) {
      list.add(name);
      await _prefs.setStringList('gensaku_exported_names', list);
    }
  }

  Future<void> _saveAll() async {
    await _prefs.setString(_key, Chapter.listToJson(_chapters));
  }

  Future<void> _addChapter() async {
    final res = await showDialog<Chapter>(context: context, builder: (_) => const ChapterModal());
    if (!mounted) return;
    if (res != null) {
      setState(() => _chapters.add(res));
      await _saveAll();
    }
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _chapters.removeAt(oldIndex);
    _chapters.insert(newIndex, item);
    setState(() {});
    await _saveAll();
  }

  Future<void> _exportBook() async {
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController(text: widget.book.title.replaceAll(RegExp(r"[^a-zA-Z0-9 _-]"), ''));
    final chosen = await showDialog<String?>(context: context, builder: (c) => AlertDialog(
          title: const Text('Export book'),
          content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'File name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(c, nameController.text.trim()), child: const Text('Export')),
          ],
        ));
    if (!mounted) return;
    if (chosen == null || chosen.isEmpty) return;

    final baseName = chosen.endsWith('.json') ? chosen : '$chosen.json';
    final existing = _exportedNames;
    String finalName = baseName;
    if (existing.contains(baseName)) {
      final action = await showDialog<String?>(context: context, builder: (c) => AlertDialog(
            title: const Text('File exists'),
            content: Text('A file named "$baseName" already exists. Replace or keep a copy?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, 'replace'), child: const Text('Replace')),
              TextButton(onPressed: () => Navigator.pop(c, 'copy'), child: const Text('Keep copy')),
            ],
          ));
      if (!mounted) return;
      if (action == 'replace') {
        finalName = baseName;
      } else if (action == 'copy') {
        var i = 1;
        while (existing.contains(finalName)) {
          finalName = '$chosen(${i++}).json';
        }
      } else {
        return;
      }
    }

    // include chapters and sidebar data with the export so it can be imported back
    final sidebarKey = 'gensaku_sidebar_${widget.book.id}';
    final sidebarRaw = _prefs.getString(sidebarKey);
    final sidebarJson = sidebarRaw == null ? [] : jsonDecode(sidebarRaw);
    final payloadMap = {
      'book': widget.book.toJson(),
      'chapters': _chapters.map((c) => c.toJson()).toList(),
      'sidebar': sidebarJson,
    };
    final payload = jsonEncode(payloadMap);
    try {
      await export_import.exportJsonWeb(finalName, payload);
      if (!mounted) return;
      await _saveExportName(finalName);
      messenger.showSnackBar(const SnackBar(content: Text('Exported')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importIntoBook() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      final data = await export_import.importJsonWeb();
      if (!mounted) return;
      if (data == null || data.isEmpty) return;
      final parsed = jsonDecode(data);
      List<Chapter> incoming = [];
      // support full-export format with book/chapters/sidebar
      if (parsed is Map && parsed.containsKey('chapters')) {
        final ch = parsed['chapters'] as List<dynamic>;
        incoming = ch.map((e) => Chapter.fromJson(e as Map<String, dynamic>)).toList();
        // import sidebar if present
        if (parsed.containsKey('sidebar')) {
          final sidebarKey = 'gensaku_sidebar_${widget.book.id}';
          try {
            final rawSidebar = jsonEncode(parsed['sidebar']);
            await _prefs.setString(sidebarKey, rawSidebar);
          } catch (_) {}
        }
      } else if (parsed is List) {
        incoming = parsed.map((e) => Chapter.fromJson(e as Map<String, dynamic>)).toList();
      } else if (parsed is Map && parsed.containsKey('number')) {
        incoming = [Chapter.fromJson(parsed as Map<String, dynamic>)];
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Imported file not recognized')));
        return;
      }

      if (!mounted) return;
      final choice = await showDialog<String?>(context: context, builder: (c) => AlertDialog(
            title: const Text('Import chapters'),
            content: const Text('Replace existing chapters or append imported chapters?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, 'append'), child: const Text('Append')),
              TextButton(onPressed: () => Navigator.pop(c, 'replace'), child: const Text('Replace')),
            ],
          ));
      if (!mounted) return;
      if (choice == null) return;
      if (choice == 'replace') {
        setState(() => _chapters = incoming);
      } else {
        setState(() => _chapters.addAll(incoming));
      }
      await _saveAll();
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _editChapter(Chapter c, int idx) async {
    final res = await showDialog<Chapter>(context: context, builder: (_) => ChapterModal(initial: c));
    if (!mounted) return;
    if (res != null) {
      setState(() => _chapters[idx] = res);
      await _saveAll();
    }
  }

  Future<void> _openEditor(Chapter c, int idx) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChapterEditorScreen(chapter: c, onSave: (updated) async {
      if (!mounted) return;
      setState(() => _chapters[idx] = updated);
      await _saveAll();
    })));
  }

  Future<void> _deleteChapter(int idx) async {
    setState(() => _chapters.removeAt(idx));
    await _saveAll();
  }

  @override
  Widget build(BuildContext context) {
    // Layout: left sidebar (persistent on wide screens) + main content
    final isSmall = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      drawer: isSmall ? Drawer(child: SafeArea(child: Sidebar(bookId: widget.book.id))) : null,
      bottomNavigationBar: NavigationPanel(selectedIndex: 0, onDestinationSelected: (i) => Navigator.popUntil(context, (r) => r.isFirst)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar on left (persistent on large screens)
              if (!isSmall) ...[
                SizedBox(width: 320, child: Sidebar(bookId: widget.book.id)),
                const VerticalDivider(width: 24),
              ],
              // Main content
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Back button
                        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
                        Expanded(child: Text(widget.book.title, style: Theme.of(context).textTheme.headlineSmall)),
                        IconButton(onPressed: _addChapter, icon: const Icon(Icons.add)),
                        PopupMenuButton<String>(onSelected: (v) async {
                          final messenger = ScaffoldMessenger.of(context);
                          if (v == 'export') await _exportBook();
                          if (v == 'import') await _importIntoBook();
                          if (v == 'sync') messenger.showSnackBar(const SnackBar(content: Text('Sync not implemented')));
                        }, itemBuilder: (_) => const [PopupMenuItem(value: 'export', child: Text('Export')), PopupMenuItem(value: 'import', child: Text('Import')), PopupMenuItem(value: 'sync', child: Text('Sync'))]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _chapters.isEmpty
                          ? Center(child: Text('No chapters yet', style: Theme.of(context).textTheme.bodyLarge))
                          : ReorderableListView.builder(
                              itemCount: _chapters.length,
                              onReorder: _onReorder,
                              proxyDecorator: (widget, index, animation) => Material(elevation: 6, child: widget),
                              itemBuilder: (context, index) {
                                final c = _chapters[index];
                                final displayNumber = c.number;
                                final titleText = c.title == null || c.title!.isEmpty ? 'Chapter $displayNumber' : 'Chapter $displayNumber: ${c.title}';
                                return ListTile(
                                  key: ValueKey(c.id),
                                  leading: CircleAvatar(child: Text('$displayNumber')),
                                  title: Text(titleText),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (c.description != null) Text(c.description!),
                                      Text('Date: ${c.createdAt.toLocal().toIso8601String().split('T').first}', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(onPressed: () => _editChapter(c, index), icon: const Icon(Icons.edit_outlined)),
                                    IconButton(onPressed: () => _deleteChapter(index), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                                  ]),
                                  onTap: () => _openEditor(c, index),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isSmall
          ? Builder(builder: (fabContext) {
              return FloatingActionButton(
                onPressed: () => Scaffold.of(fabContext).openDrawer(),
                tooltip: 'Tools',
                child: const Icon(Icons.menu),
              );
            })
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
