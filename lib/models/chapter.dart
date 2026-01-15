import 'dart:convert';

class Chapter {
  final String id;
  final String? title;
  final int number;
  String? content; // stored as Quill delta JSON or plain text
  final String? description;
  final DateTime createdAt;

  Chapter({
    required this.id,
    this.title,
    required this.number,
    this.content,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'number': number,
        'content': content,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        id: j['id'] as String,
        title: j['title'] as String?,
        number: (j['number'] is int) ? j['number'] as int : int.tryParse('${j['number']}') ?? 0,
        content: j['content'] as String?,
        description: j['description'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  static List<Chapter> listFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = json.decode(jsonStr) as List<dynamic>;
      return list.map((e) => Chapter.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<Chapter> chapters) => json.encode(chapters.map((c) => c.toJson()).toList());
}
