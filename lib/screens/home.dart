import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/header.dart';
import '../widgets/book.dart';
import 'book_screen.dart';
import '../widgets/bookmodal.dart';
import '../core/book_store.dart';
import '../core/export_import.dart' as export_import;

class HomePage extends StatefulWidget {
  final ThemeNotifier notifier;
  const HomePage({required this.notifier, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Book> _books;

  @override
  void initState() {
    super.initState();
    _books = [];
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final list = await BookStore.load();
    if (!mounted) return;
    setState(() => _books = list);
  }

  Future<void> _openEditor() async {
    final book = await showDialog<Book>(context: context, builder: (_) => const BookModal());
    if (book != null) {
      setState(() => _books.insert(0, book));
      await BookStore.save(_books);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive panel width and padding
            double panelWidth;
            EdgeInsets contentPadding;

            if (constraints.maxWidth >= 1200) {
              panelWidth = 1200;
              contentPadding = const EdgeInsets.all(24);
            } else if (constraints.maxWidth >= 800) {
              panelWidth = constraints.maxWidth * 0.95;
              contentPadding = const EdgeInsets.all(20);
            } else {
              panelWidth = constraints.maxWidth;
              contentPadding = const EdgeInsets.all(16);
            }

            return Center(
              child: SizedBox(
                width: panelWidth,
                child: Column(
                  children: [
                    Header(notifier: widget.notifier, onNew: _openEditor),
                    const SizedBox(height: 16),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: contentPadding,
                            sliver: SliverToBoxAdapter(
                              child: BookCanvas(
                                books: _books,
                                onOpen: (book) async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => BookScreen(book: book)),
                                  );
                                  await _loadBooks();
                                },
                                onEdit: (book) async {
                                  final edited = await showDialog<Book>(
                                    context: context,
                                    builder: (_) => BookModal(initial: book),
                                  );
                                  if (edited != null) {
                                    final idx = _books.indexWhere((b) => b.id == book.id);
                                    if (idx != -1) setState(() => _books[idx] = edited);
                                    await BookStore.save(_books);
                                  }
                                },
                                onDelete: (book) async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      icon: Icon(Icons.delete_rounded, color: theme.colorScheme.error),
                                      title: const Text('Delete book?'),
                                      content: const Text('This will permanently delete the book and all its chapters.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(c, true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: theme.colorScheme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    setState(() => _books.removeWhere((b) => b.id == book.id));
                                    await BookStore.save(_books);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final value = await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded),
                    title: const Text('Sync'),
                    subtitle: const Text('Coming soon'),
                    onTap: () => Navigator.pop(context, 'sync'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload_rounded),
                    title: const Text('Export'),
                    subtitle: const Text('Save your books as JSON'),
                    onTap: () => Navigator.pop(context, 'export'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: const Text('Import'),
                    subtitle: const Text('Load books from JSON'),
                    onTap: () => Navigator.pop(context, 'import'),
                  ),
                ],
              ),
            ),
          );

          if (value == 'export') {
            final json = await BookStore.load().then((list) => list.map((b) => b.toJson()).toList()).then((l) => jsonEncode(l));
            if (json.isNotEmpty) await export_import.exportJsonWeb('gensaku_books.json', json);
          } else if (value == 'import') {
            final data = await export_import.importJsonWeb();
            if (data != null && data.isNotEmpty) {
              if (!mounted) return;
              try {
                final list = jsonDecode(data) as List<dynamic>;
                final books = list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
                setState(() => _books = books);
                await BookStore.save(_books);
              } catch (e) {
                // ignore
              }
            }
          } else if (value == 'sync') {
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Sync feature coming soon!')),
            );
          }
        },
        icon: const Icon(Icons.more_vert_rounded),
        label: const Text('More'),
      ),
    );
  }

}

