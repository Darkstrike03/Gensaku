import 'package:flutter/material.dart';
import 'package:gensaku/models/chapter.dart';

class ChapterEditorScreen extends StatefulWidget {
  final Chapter chapter;
  final void Function(Chapter updated) onSave;

  const ChapterEditorScreen({required this.chapter, required this.onSave, super.key});

  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen> {
  late TextEditingController _controller;
  double _fontSize = 16;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.chapter.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyWrap(String left, String right) {
    final sel = _controller.selection;
    final text = _controller.text;
    if (!sel.isValid) return;
    final start = sel.start;
    final end = sel.end;
    final before = text.substring(0, start);
    final selected = text.substring(start, end);
    final after = text.substring(end);
    final replaced = '$before$left$selected$right$after';
    final newOffset = start + left.length + selected.length + right.length;
    _controller.value = TextEditingValue(text: replaced, selection: TextSelection.collapsed(offset: newOffset));
  }

  void _save() {
    final updated = Chapter(
      id: widget.chapter.id,
      title: widget.chapter.title,
      number: widget.chapter.number,
      description: widget.chapter.description,
      content: _controller.text,
      createdAt: widget.chapter.createdAt,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title ?? 'Chapter ${widget.chapter.number}'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(onPressed: () => _applyWrap('**', '**'), icon: const Icon(Icons.format_bold)),
                IconButton(onPressed: () => _applyWrap('*', '*'), icon: const Icon(Icons.format_italic)),
                IconButton(onPressed: () => _applyWrap('__', '__'), icon: const Icon(Icons.format_underline)),
                IconButton(onPressed: () => _applyWrap('-', '\n- '), icon: const Icon(Icons.format_list_bulleted)),
                const Spacer(),
                IconButton(onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(12, 36)), icon: const Icon(Icons.text_increase)),
                IconButton(onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(12, 36)), icon: const Icon(Icons.text_decrease)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: TextStyle(fontSize: _fontSize),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Write your notes...'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
