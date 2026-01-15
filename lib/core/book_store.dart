import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/book.dart';

class BookStore {
  static const _prefsKey = 'gensaku_books';

  // Load books from browser storage (web) or prefs (mobile/desktop).
  static Future<List<Book>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data == null || data.isEmpty) return [];
    final list = json.decode(data) as List<dynamic>;
    return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(books.map((b) => b.toJson()).toList());
    await prefs.setString(_prefsKey, data);
  }

  static Future<void> add(Book book) async {
    final list = await load();
    list.insert(0, book);
    await save(list);
  }

  // Optional: export as downloadable JSON (for web) — not used yet.
}
