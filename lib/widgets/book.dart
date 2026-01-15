// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// bookmodal.dart is used from Home; not required here

class Book {
  final String id;
  final String title;
  final String? imageUrl;
  final String? synopsis;
  final DateTime date;

  Book({
    required this.id,
    required this.title,
    this.imageUrl,
    this.synopsis,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'synopsis': synopsis,
        'date': date.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String?,
        synopsis: json['synopsis'] as String?,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const BookCard({required this.book, this.onEdit, this.onDelete, this.onTap, super.key});

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  double? _aspect; // width / height
  ImageProvider? _provider;

  static const double _maxHeight = 600;
  static const double _minHeight = 140;

  @override
  void initState() {
    super.initState();
    _prepareImage();
  }

  @override
  void didUpdateWidget(covariant BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.imageUrl != widget.book.imageUrl) {
      _aspect = null;
      _provider = null;
      _prepareImage();
    }
  }

  void _prepareImage() {
    final img = widget.book.imageUrl;
    if (img == null || img.isEmpty) return;

    try {
      if (img.startsWith('data:')) {
        final parts = img.split(',');
        if (parts.length == 2) {
          final bytes = base64.decode(parts[1]);
          _provider = MemoryImage(bytes);
        }
      } else if (img.startsWith('http')) {
        _provider = NetworkImage(img);
      } else {
        if (!kIsWeb) {
          _provider = FileImage(File(img));
        }
      }
    } catch (_) {
      _provider = null;
    }

    if (_provider != null) {
      final resolver = _provider!.resolve(const ImageConfiguration());
      resolver.addListener(ImageStreamListener((info, synchronousCall) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w > 0 && h > 0) {
          setState(() => _aspect = w / h);
        }
      }, onError: (error, stack) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: _provider == null
            ? _buildTextContent(theme)
            : _buildImageContent(theme),
      ),
    );
  }

  Widget _buildTextContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.book.title,
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.book.synopsis != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.book.synopsis!,
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.book.date.toLocal().toIso8601String().split('T').first,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: widget.onEdit,
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 18),
                onPressed: widget.onDelete,
                color: theme.colorScheme.error,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth;
        double height;
        if (_aspect != null && _aspect! > 0) {
          height = colWidth / _aspect!;
          if (height > _maxHeight) height = _maxHeight;
          if (height < _minHeight) height = _minHeight;
        } else {
          height = colWidth * 3 / 4;
        }

        return SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image(image: _provider!, fit: BoxFit.cover),
              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.book.title,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.book.synopsis != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.book.synopsis!,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.book.date.toLocal().toIso8601String().split('T').first,
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: widget.onEdit,
                          color: Colors.white,
                          tooltip: 'Edit',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          onPressed: widget.onDelete,
                          color: Colors.white,
                          tooltip: 'Delete',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BookEditor extends StatefulWidget {
  final Book? initial;

  const BookEditor({this.initial, super.key});

  @override
  State<BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<BookEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _synopsisController;
  late TextEditingController _imageController;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _synopsisController = TextEditingController(text: widget.initial?.synopsis ?? '');
    _imageController = TextEditingController(text: widget.initial?.imageUrl ?? '');
    _date = widget.initial?.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    _imageController.dispose();
    super.dispose();
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
      imageUrl: _imageController.text.trim().isEmpty ? null : _imageController.text.trim(),
      synopsis: _synopsisController.text.trim().isEmpty ? null : _synopsisController.text.trim(),
      date: _date,
    );
    Navigator.of(context).pop(book);
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
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Book title'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _synopsisController,
                      decoration: const InputDecoration(labelText: 'Synopsis (optional)'),
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_date == null ? 'Date: (today)' : 'Date: ${_date!.toLocal().toIso8601String().split('T').first}'),
                        ),
                        TextButton(onPressed: _pickDate, child: const Text('Pick Date')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive canvas/grid for books. Use `addBook` to append.
class BookCanvas extends StatelessWidget {
  final List<Book> books;
  final void Function()? onAdd;
  final void Function(Book book)? onEdit;
  final void Function(Book book)? onDelete;
  final void Function(Book book)? onOpen;

  const BookCanvas({required this.books, this.onAdd, this.onEdit, this.onDelete, this.onOpen, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onAdd != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('New Book'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(builder: (context, constraints) {
  final width = constraints.maxWidth;
  int columns;
  
  if (width > 1200) {
    columns = 4;
  } else if (width > 900) {
    columns = 3;
  } else if (width > 600) {
    columns = 2;
  } else {
    columns = 2;
  }

  return MasonryGridView.count(
    crossAxisCount: columns,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    itemCount: books.length,
    shrinkWrap: true,
    padding: EdgeInsets.zero, // Add this line - removes default padding
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) {
      final b = books[index];
      return BookCard(
        book: b,
        onEdit: () => onEdit?.call(b),
        onDelete: () => onDelete?.call(b),
        onTap: () => onOpen?.call(b),
      );
    },
  );
}),
      ],
    );
  }
}
