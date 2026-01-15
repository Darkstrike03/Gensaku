import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gensaku/models/chapter.dart';

class ChapterModal extends StatefulWidget {
  final Chapter? initial;

  const ChapterModal({this.initial, super.key});

  @override
  State<ChapterModal> createState() => _ChapterModalState();
}

class _ChapterModalState extends State<ChapterModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _numberController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _numberController = TextEditingController(text: widget.initial?.number.toString() ?? '1');
    _descController = TextEditingController(text: widget.initial?.description ?? '');
    _selectedDate = widget.initial?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final chapter = Chapter(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      number: int.tryParse(_numberController.text.trim()) ?? 1,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      content: widget.initial?.content,
      createdAt: _selectedDate ?? widget.initial?.createdAt,
    );
    Navigator.of(context).pop(chapter);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Chapter title (optional)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(labelText: 'Chapter number'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Provide a number' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Short description (optional)'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(_selectedDate == null ? 'Date: (today)' : 'Date: ${_selectedDate!.toLocal().toIso8601String().split('T').first}')),
                      TextButton(onPressed: _pickDate, child: const Text('Pick Date')),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _save, child: const Text('Save')),
              ])
            ],
          ),
        ),
      ),
    );
  }
}
