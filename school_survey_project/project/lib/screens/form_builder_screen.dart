import 'package:flutter/material.dart';

import '../db.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/question_editor.dart';

class FormBuilderScreen extends StatefulWidget {
  const FormBuilderScreen({super.key, this.survey});

  /// Null = create a new survey, otherwise edit this one.
  final Survey? survey;

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _title = TextEditingController();
  final List<Question> _qs = [];
  bool _loading = false;
  bool _saving = false;
  String? _titleError;
  String? _listError;

  @override
  void initState() {
    super.initState();
    final s = widget.survey;
    if (s != null) {
      _title.text = s.title;
      _loading = true;
      SurveyDb.I.questions(s.id).then((qs) {
        if (!mounted) return;
        setState(() {
          _qs.addAll(qs);
          _loading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _editQuestion(int? index) async {
    final result = await showModalBottomSheet<Question>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => QuestionEditor(initial: index == null ? null : _qs[index]),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (index == null) {
        _qs.add(result);
      } else {
        _qs[index] = result;
      }
      _listError = null;
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final q = _qs.removeAt(oldIndex);
      _qs.insert(newIndex, q);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    setState(() {
      _titleError = title.isEmpty ? context.tr('titleRequired') : null;
      _listError = _qs.isEmpty ? context.tr('addAtLeastOne') : null;
    });
    if (_titleError != null || _listError != null) return;
    setState(() => _saving = true);
    final failMsg = context.tr('saveFailed');
    try {
      final s = widget.survey;
      if (s == null) {
        await SurveyDb.I.createSurvey(title, _qs);
      } else {
        await SurveyDb.I.updateSurvey(s.id, title, _qs);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMsg)));
    }
  }

  String _subtitle(BuildContext context, Question q) {
    final parts = <String>[context.tr(q.type.labelKey)];
    if (q.type.hasOptions) parts.add('${q.options.length} ${context.tr('options').toLowerCase()}');
    if (q.isRequired) parts.add(context.tr('required'));
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.survey != null;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(editing ? 'editSurvey' : 'newSurvey'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(context.tr('save')),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  buildDefaultDragHandles: false,
                  onReorder: _reorder,
                  itemCount: _qs.length,
                  header: _header(context, editing),
                  footer: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _editQuestion(null),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.tr('addQuestion')),
                    ),
                  ),
                  itemBuilder: (context, i) {
                    final q = _qs[i];
                    return Card(
                      key: ValueKey(q.id),
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: kBorder, width: 2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsetsDirectional.only(start: 4, end: 4),
                        onTap: () => _editQuestion(i),
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.drag_indicator_rounded, color: kMuted),
                          ),
                        ),
                        title: Text(q.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        subtitle: Text(_subtitle(context, q)),
                        trailing: IconButton(
                          tooltip: context.tr('delete'),
                          icon: const Icon(Icons.delete_outline_rounded, color: kDanger),
                          onPressed: () => setState(() => _qs.removeAt(i)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _header(BuildContext context, bool editing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (editing)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF8A6100)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr('editWarning'),
                    style: const TextStyle(color: Color(0xFF5C4100))),
              ),
            ]),
          ),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 18),
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
          decoration: InputDecoration(
            labelText: context.tr('surveyTitle'),
            hintText: context.tr('surveyTitleHint'),
            errorText: _titleError,
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Text(context.tr('questions'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('(${_qs.length})', style: const TextStyle(fontSize: 16, color: kMuted)),
        ]),
        const SizedBox(height: 8),
        if (_listError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_listError!, style: const TextStyle(color: kDanger, fontSize: 15)),
          ),
        if (_qs.isEmpty && _listError == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(context.tr('noQuestions'),
                style: const TextStyle(fontSize: 15, color: kMuted)),
          ),
      ],
    );
  }
}
