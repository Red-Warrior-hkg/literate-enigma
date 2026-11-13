import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db.dart';
import '../l10n.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/question_field.dart';

/// Data-collection screen: the surveyor fills the form for a student,
/// taps Save, and the form resets for the next student.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.survey, required this.settings});

  final Survey survey;
  final Settings settings;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  List<Question> _qs = const [];
  bool _loading = true;
  final Map<String, dynamic> _answers = {};
  final Map<String, String> _errors = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, GlobalKey> _keys = {};
  final ScrollController _scroll = ScrollController();
  int _count = 0;
  bool _saving = false;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final qs = await SurveyDb.I.questions(widget.survey.id);
    final total = await SurveyDb.I.count(widget.survey.id);
    for (final q in qs) {
      _keys[q.id] = GlobalKey();
      if (q.type == QType.text || q.type == QType.number) {
        _controllers[q.id] = TextEditingController();
      }
    }
    if (!mounted) return;
    setState(() {
      _qs = qs;
      _count = total;
      _loading = false;
    });
  }

  void _setAnswer(String id, dynamic v) {
    final value = v is String ? v.trim() : v;
    final empty = value == null || (value is String && value.isEmpty) || (value is List && value.isEmpty);
    setState(() {
      if (empty) {
        _answers.remove(id);
      } else {
        _answers[id] = value;
      }
      _errors.remove(id);
    });
  }

  bool _validate() {
    final errs = <String, String>{};
    for (final q in _qs) {
      if (q.isRequired && !_answers.containsKey(q.id)) {
        errs[q.id] = context.tr('pleaseAnswer');
      }
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errs);
    });
    if (errs.isNotEmpty) {
      final firstId = _qs.firstWhere((q) => errs.containsKey(q.id)).id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[firstId]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.1);
        }
      });
    }
    return errs.isEmpty;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    final failMsg = context.tr('saveFailed');
    try {
      await SurveyDb.I.saveResponse(
        widget.survey.id,
        Map<String, dynamic>.of(_answers),
        surveyor: widget.settings.surveyor,
      );
      final total = await SurveyDb.I.count(widget.survey.id);
      if (!mounted) return;
      for (final c in _controllers.values) {
        c.clear();
      }
      setState(() {
        _answers.clear();
        _errors.clear();
        _count = total;
        _showSaved = true;
      });
      HapticFeedback.mediumImpact();
      if (_scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _showSaved = false);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMsg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLeave() async {
    final discard = await confirmDialog(
      context,
      title: context.tr('discardQ'),
      message: context.tr('discardMsg'),
      confirmLabel: context.tr('discard'),
      danger: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _answers.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.survey.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.save_alt_rounded, size: 18, color: kMint),
                  label: Text(context.trn('totalSaved', _count)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: kBorder),
                ),
              ),
            ),
          ],
        ),
        body: Stack(children: [
          _body(context),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedScale(
                  scale: _showSaved ? 1 : 0.6,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _showSaved ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                      decoration: BoxDecoration(
                        color: kMint,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_circle_rounded, size: 72, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(context.tr('savedLocally'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_qs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.tr('noQuestionsInSurvey'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, color: kMuted)),
        ),
      );
    }
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final q in _qs)
                  QuestionField(
                    key: _keys[q.id],
                    question: q,
                    value: _answers[q.id],
                    error: _errors[q.id],
                    controller: _controllers[q.id],
                    onChanged: (v) => _setAnswer(q.id, v),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check_rounded, size: 26),
                  label: Text(context.tr('saveResponse')),
                  style: FilledButton.styleFrom(minimumSize: const Size(88, 64)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
