import 'package:flutter/material.dart';

import '../db.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/export_flow.dart';

class ResponsesScreen extends StatefulWidget {
  const ResponsesScreen({super.key, required this.survey});

  final Survey survey;

  @override
  State<ResponsesScreen> createState() => _ResponsesScreenState();
}

class _ResponsesScreenState extends State<ResponsesScreen> {
  List<Question> _qs = const [];
  List<ResponseRow> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final qs = await SurveyDb.I.questions(widget.survey.id);
    final rs = await SurveyDb.I.responses(widget.survey.id);
    if (!mounted) return;
    setState(() {
      _qs = qs;
      _rows = rs.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _delete(ResponseRow r) async {
    final ok = await confirmDialog(
      context,
      title: context.tr('deleteResponseQ'),
      confirmLabel: context.tr('delete'),
      danger: true,
    );
    if (!ok) return;
    await SurveyDb.I.deleteResponse(r.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Builder(
            builder: (btnContext) => IconButton(
              tooltip: context.tr('export'),
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => exportFlow(btnContext, widget.survey),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? Center(
                  child: Text(context.tr('noResponses'),
                      style: const TextStyle(fontSize: 18, color: kMuted)),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _rows.length,
                      itemBuilder: (context, i) => _tile(context, i, lang),
                    ),
                  ),
                ),
    );
  }

  Widget _tile(BuildContext context, int i, String lang) {
    final r = _rows[i];
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder, width: 2),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text('#${_rows.length - i}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        subtitle: Text(
          r.surveyor.isEmpty ? fmtDate(r.createdAt) : '${fmtDate(r.createdAt)}  ·  ${r.surveyor}',
        ),
        children: [
          for (final q in _qs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.label, style: const TextStyle(fontSize: 13, color: kMuted)),
                  const SizedBox(height: 2),
                  Builder(builder: (_) {
                    final a = answerText(q, r.answers[q.id], lang);
                    return Text(a.isEmpty ? '—' : a,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
                  }),
                ],
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => _delete(r),
              icon: const Icon(Icons.delete_outline_rounded, color: kDanger),
              label: Text(context.tr('delete'), style: const TextStyle(color: kDanger)),
            ),
          ),
        ],
      ),
    );
  }
}
