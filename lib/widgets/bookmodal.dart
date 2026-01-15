import 'dart:convert';
import 'dart:io' show File;

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'book.dart';

class BookModal extends StatefulWidget {
  final Book? initial;

  const BookModal({this.initial, super.key});

  @override
  State<BookModal> createState() => _BookModalState();
}

class _BookModalState extends State<BookModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _synopsisController;
  DateTime? _date;

  // Local image representation: either a file path (desktop/mobile) or a data URI for web
  String? _imageSource;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _synopsisController = TextEditingController(text: widget.initial?.synopsis ?? '');
    _date = widget.initial?.date;
    _imageSource = widget.initial?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        if (bytes.isNotEmpty) {
          // determine mime from extension
          String mime = 'image/png';
          final name = picked.name;
          final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
          switch (ext) {
            case 'jpg':
            case 'jpeg':
              mime = 'image/jpeg';
              break;
            case 'png':
              mime = 'image/png';
              break;
            case 'gif':
              mime = 'image/gif';
              break;
            case 'webp':
              mime = 'image/webp';
              break;
          }
          final b64 = base64.encode(bytes);
          if (!mounted) return;
          setState(() {
            _imageSource = 'data:$mime;base64,$b64';
            _previewBytes = bytes;
          });
        }
      } else {
        final path = picked.path;
        if (path.isNotEmpty) {
          if (!mounted) return;
          setState(() => _imageSource = path);
        }
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Error selecting image'),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final book = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      imageUrl: _imageSource?.trim().isEmpty == true ? null : _imageSource,
      synopsis: _synopsisController.text.trim().isEmpty ? null : _synopsisController.text.trim(),
      date: _date,
    );
    Navigator.of(context).pop(book);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget? preview;
    if (_previewBytes != null) {
      preview = Image.memory(_previewBytes!, fit: BoxFit.cover);
    } else if (_imageSource != null && _imageSource!.isNotEmpty && !kIsWeb) {
      preview = Image.file(File(_imageSource!), fit: BoxFit.cover);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.initial == null ? 'Create New Book' : 'Edit Book',
                        style: GoogleFonts.caveat(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.literata(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Book Title',
                          hintText: 'Enter title...',
                          prefixIcon: const Icon(Icons.title_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Cover Image Section
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withAlpha((0.3 * 255).round()),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.5),
                            child: preview ?? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 40,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add cover',
                                  style: GoogleFonts.literata(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Synopsis Field
                      TextFormField(
                        controller: _synopsisController,
                        style: GoogleFonts.literata(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Synopsis (optional)',
                          hintText: 'Write a brief synopsis...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date Picker
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _date == null 
                                  ? 'Date: Today' 
                                  : 'Date: ${_date!.toLocal().toIso8601String().split('T').first}',
                                style: GoogleFonts.literata(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _pickDate,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
