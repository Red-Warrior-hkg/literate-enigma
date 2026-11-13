import 'dart:convert';

import 'l10n.dart';

enum QType { yesNo, text, number, singleChoice, dropdown, multiChoice }

extension QTypeX on QType {
  String get labelKey {
    switch (this) {
      case QType.yesNo:
        return 'typeYesNo';
      case QType.text:
        return 'typeText';
      case QType.number:
        return 'typeNumber';
      case QType.singleChoice:
        return 'typeSingle';
      case QType.dropdown:
        return 'typeDropdown';
      case QType.multiChoice:
        return 'typeMulti';
    }
  }

  bool get hasOptions =>
      this == QType.singleChoice || this == QType.dropdown || this == QType.multiChoice;
}

class Question {
  const Question({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options = const [],
  });

  final String id;
  final String label;
  final QType type;
  final bool isRequired;
  final List<String> options;

  Map<String, Object?> toMap(String surveyId, int position) => {
        'id': id,
        'survey_id': surveyId,
        'position': position,
        'label': label,
        'type': type.name,
        'is_required': isRequired ? 1 : 0,
        'options_json': jsonEncode(options),
      };

  factory Question.fromMap(Map<String, Object?> m) => Question(
        id: m['id'] as String,
        label: m['label'] as String,
        type: QType.values.byName(m['type'] as String),
        isRequired: (m['is_required'] as int) == 1,
        options: (jsonDecode(m['options_json'] as String) as List).cast<String>(),
      );
}

class Survey {
  const Survey({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.responseCount,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final int responseCount;
}

class ResponseRow {
  const ResponseRow({
    required this.id,
    required this.surveyor,
    required this.createdAt,
    required this.answers,
  });

  final String id;
  final String surveyor;
  final DateTime createdAt;
  final Map<String, dynamic> answers;
}

/// Human readable text of one answer, in the given language.
String answerText(Question q, dynamic v, String lang) {
  if (v == null) return '';
  if (q.type == QType.yesNo) {
    if (v == 'yes') return trLang(lang, 'yes');
    if (v == 'no') return trLang(lang, 'no');
  }
  if (v is List) return v.join('; ');
  return '$v';
}

String fmtDate(DateTime d) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
}
