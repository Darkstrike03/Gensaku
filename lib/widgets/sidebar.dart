import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SidebarItem {
  String id;
  String name;
  String? description;
  String? imageUrl;
  String? notes;

  SidebarItem({required this.id, required this.name, this.description, this.imageUrl, this.notes});

  factory SidebarItem.fromJson(Map<String, dynamic> j) => SidebarItem(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        imageUrl: j['imageUrl'] as String?,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'imageUrl': imageUrl, 'notes': notes};
}

class SidebarCategory {
  String id;
  String name;
  List<SidebarItem> items;

  SidebarCategory({required this.id, required this.name, List<SidebarItem>? items}) : items = items ?? [];

  factory SidebarCategory.fromJson(Map<String, dynamic> j) => SidebarCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        items: (j['items'] as List<dynamic>?)?.map((e) => SidebarItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'items': items.map((e) => e.toJson()).toList()};
}

class Sidebar extends StatefulWidget {
  final String bookId;

  const Sidebar({required this.bookId, super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late SharedPreferences _prefs;
  List<SidebarCategory> _categories = [];

  String get _key => 'gensaku_sidebar_${widget.bookId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null) {
      // initialize with presets
      _categories = [
        SidebarCategory(id: 'preset_mc', name: 'Main Characters'),
        SidebarCategory(id: 'preset_sc', name: 'Side Characters'),
        SidebarCategory(id: 'preset_vill', name: 'Villains'),
        SidebarCategory(id: 'preset_mon', name: 'Monsters'),
        SidebarCategory(id: 'preset_ps', name: 'Power System'),
        SidebarCategory(id: 'preset_sk', name: 'Skills'),
        SidebarCategory(id: 'preset_r', name: 'Races'),
      ];
      await _save();
      return;
    }
    try {
      final parsed = jsonDecode(raw) as List<dynamic>;
      setState(() => _categories = parsed.map((e) => SidebarCategory.fromJson(e as Map<String, dynamic>)).toList());
    } catch (_) {
      // ignore
    }
  }

  Future<void> _save() async {
    final payload = jsonEncode(_categories.map((c) => c.toJson()).toList());
    await _prefs.setString(_key, payload);
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String?>(context: context, builder: (c) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: const Text('New category'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Category name')),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Add'))],
      );
    });
    if (name == null || name.isEmpty) return;
    final cat = SidebarCategory(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name);
    setState(() => _categories.add(cat));
    await _save();
  }

  Future<void> _editCategory(SidebarCategory cat) async {
    final name = await showDialog<String?>(context: context, builder: (c) {
      final ctrl = TextEditingController(text: cat.name);
      return AlertDialog(
        title: const Text('Edit category'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Category name')),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Save'))],
      );
    });
    if (name == null || name.isEmpty) return;
    setState(() => cat.name = name);
    await _save();
  }

  Future<void> _removeCategory(SidebarCategory cat) async {
    final ok = await showDialog<bool?>(context: context, builder: (c) => AlertDialog(
          title: const Text('Delete category'),
          content: Text('Delete category "${cat.name}" and all its items?'),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
        ));
    if (ok != true) return;
    setState(() => _categories.removeWhere((e) => e.id == cat.id));
    await _save();
  }

  Future<SidebarItem?> _showItemDialog([SidebarItem? initial]) async {
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final descCtrl = TextEditingController(text: initial?.description ?? '');
    final imgCtrl = TextEditingController(text: initial?.imageUrl ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    final res = await showDialog<SidebarItem?>(context: context, builder: (c) => AlertDialog(
          title: Text(initial == null ? 'New item' : 'Edit item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
                const SizedBox(height: 8),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 6),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  final id = initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
                  Navigator.pop(c, SidebarItem(id: id, name: nameCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), imageUrl: imgCtrl.text.trim().isEmpty ? null : imgCtrl.text.trim(), notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()));
                },
                child: const Text('Save'))
          ],
        ));
    return res;
  }

  Future<void> _openItemNotes(SidebarCategory cat, SidebarItem item) async {
    final notesCtrl = TextEditingController(text: item.notes ?? '');
    final res = await showDialog<bool?>(context: context, builder: (c) => AlertDialog(
          title: Text(item.name),
          content: SizedBox(height: 300, child: TextField(controller: notesCtrl, maxLines: null, expands: true, decoration: const InputDecoration(border: OutlineInputBorder()))),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
        ));
    if (res == true) {
      item.notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
      await _save();
      setState(() {});
    }
  }

  Future<void> _addItem(SidebarCategory cat) async {
    final item = await _showItemDialog();
    if (item == null) return;
    setState(() => cat.items.add(item));
    await _save();
  }

  Future<void> _editItem(SidebarCategory cat, SidebarItem item) async {
    final edited = await _showItemDialog(item);
    if (edited == null) return;
    final idx = cat.items.indexWhere((i) => i.id == item.id);
    if (idx < 0) return;
    setState(() => cat.items[idx] = edited);
    await _save();
  }

  Future<void> _removeItem(SidebarCategory cat, SidebarItem item) async {
    final ok = await showDialog<bool?>(context: context, builder: (c) => AlertDialog(
          title: const Text('Delete item'),
          content: Text('Delete "${item.name}"?'),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
        ));
    if (ok != true) return;
    setState(() => cat.items.removeWhere((i) => i.id == item.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Story Toolbox', style: Theme.of(context).textTheme.titleMedium)),
                IconButton(onPressed: _addCategory, icon: const Icon(Icons.add_box_outlined)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _categories.isEmpty
                  ? Center(child: Text('No categories yet', style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        return ExpansionTile(
                          key: ValueKey(cat.id),
                          title: Row(
                            children: [
                              Expanded(child: Text(cat.name)),
                              IconButton(onPressed: () => _editCategory(cat), icon: const Icon(Icons.edit, size: 18)),
                              IconButton(onPressed: () => _removeCategory(cat), icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                            ],
                          ),
                          children: [
                            if (cat.items.isEmpty) Padding(padding: const EdgeInsets.all(8.0), child: Text('No items', style: Theme.of(context).textTheme.bodySmall)),
                            ...cat.items.map((it) => ListTile(
                                  onTap: () => _openItemNotes(cat, it),
                                  leading: it.imageUrl != null ? CircleAvatar(backgroundImage: NetworkImage(it.imageUrl!)) : CircleAvatar(child: Text(it.name.isNotEmpty ? it.name[0].toUpperCase() : '?')),
                                  title: Text(it.name),
                                  subtitle: it.description != null ? Text(it.description!) : (it.notes != null ? Text('Has notes') : null),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(onPressed: () => _editItem(cat, it), icon: const Icon(Icons.edit_outlined, size: 18)),
                                    IconButton(onPressed: () => _removeItem(cat, it), icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                                  ]),
                                )),
                            Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _addItem(cat), icon: const Icon(Icons.add, size: 18), label: const Text('Add item'))),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
