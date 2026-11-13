import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

/// Local SQLite storage. Every write is committed to disk immediately,
/// so nothing is lost if the app is closed or the battery dies.
class SurveyDb {
  SurveyDb._();
  static final SurveyDb I = SurveyDb._();
  static const _uuid = Uuid();

  Future<Database>? _opening;
  Future<Database> get db => _opening ??= _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'school_survey.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE surveys('
            'id TEXT PRIMARY KEY, title TEXT NOT NULL, created_at TEXT NOT NULL)');
        await d.execute('CREATE TABLE questions('
            'id TEXT PRIMARY KEY, survey_id TEXT NOT NULL, position INTEGER NOT NULL, '
            'label TEXT NOT NULL, type TEXT NOT NULL, is_required INTEGER NOT NULL, '
            'options_json TEXT NOT NULL)');
        await d.execute('CREATE TABLE responses('
            'id TEXT PRIMARY KEY, survey_id TEXT NOT NULL, surveyor TEXT NOT NULL, '
            'created_at TEXT NOT NULL, answers_json TEXT NOT NULL)');
        await d.execute('CREATE INDEX idx_q_survey ON questions(survey_id)');
        await d.execute('CREATE INDEX idx_r_survey ON responses(survey_id)');
      },
    );
  }

  // ---------- surveys ----------

  Future<List<Survey>> surveys() async {
    final d = await db;
    final rows = await d.rawQuery(
      'SELECT s.id, s.title, s.created_at, '
      '(SELECT COUNT(*) FROM responses r WHERE r.survey_id = s.id) AS n '
      'FROM surveys s ORDER BY s.created_at DESC',
    );
    return rows
        .map((m) => Survey(
              id: m['id'] as String,
              title: m['title'] as String,
              createdAt: DateTime.parse(m['created_at'] as String),
              responseCount: (m['n'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<String> createSurvey(String title, List<Question> qs) async {
    final d = await db;
    final id = _uuid.v4();
    await d.transaction((txn) async {
      await txn.insert('surveys', {
        'id': id,
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (var i = 0; i < qs.length; i++) {
        await txn.insert('questions', qs[i].toMap(id, i));
      }
    });
    return id;
  }

  /// Question ids are kept, so existing responses stay linked to their questions.
  Future<void> updateSurvey(String id, String title, List<Question> qs) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.update('surveys', {'title': title}, where: 'id = ?', whereArgs: [id]);
      await txn.delete('questions', where: 'survey_id = ?', whereArgs: [id]);
      for (var i = 0; i < qs.length; i++) {
        await txn.insert('questions', qs[i].toMap(id, i));
      }
    });
  }

  Future<void> deleteSurvey(String id) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('responses', where: 'survey_id = ?', whereArgs: [id]);
      await txn.delete('questions', where: 'survey_id = ?', whereArgs: [id]);
      await txn.delete('surveys', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Question>> questions(String surveyId) async {
    final d = await db;
    final rows = await d.query('questions',
        where: 'survey_id = ?', whereArgs: [surveyId], orderBy: 'position ASC');
    return rows.map(Question.fromMap).toList();
  }

  // ---------- responses ----------

  Future<void> saveResponse(String surveyId, Map<String, dynamic> answers,
      {String surveyor = ''}) async {
    final d = await db;
    await d.insert('responses', {
      'id': _uuid.v4(),
      'survey_id': surveyId,
      'surveyor': surveyor,
      'created_at': DateTime.now().toIso8601String(),
      'answers_json': jsonEncode(answers),
    });
  }

  Future<List<ResponseRow>> responses(String surveyId) async {
    final d = await db;
    final rows = await d.query('responses',
        where: 'survey_id = ?', whereArgs: [surveyId], orderBy: 'created_at ASC');
    return rows
        .map((m) => ResponseRow(
              id: m['id'] as String,
              surveyor: m['surveyor'] as String,
              createdAt: DateTime.parse(m['created_at'] as String),
              answers: jsonDecode(m['answers_json'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> deleteResponse(String id) async {
    final d = await db;
    await d.delete('responses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count(String surveyId) async {
    final d = await db;
    return Sqflite.firstIntValue(await d
            .rawQuery('SELECT COUNT(*) FROM responses WHERE survey_id = ?', [surveyId])) ??
        0;
  }
}
