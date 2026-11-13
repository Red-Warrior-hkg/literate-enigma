import 'package:flutter/material.dart';

import '../db.dart';
import '../l10n.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/export_flow.dart';
import '../widgets/settings_sheet.dart';
import 'form_builder_screen.dart';
import 'responses_screen.dart';
import 'survey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});

  final Settings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Survey> _surveys = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SurveyDb.I.surveys();
    if (!mounted) return;
    setState(() {
      _surveys = s;
      _loading = false;
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    _load();
  }

  Future<void> _deleteSurvey(Survey s) async {
    final ok = await confirmDialog(
      context,
      title: context.tr('deleteSurveyQ'),
      message: context.tr('deleteSurveyMsg'),
      confirmLabel: context.tr('delete'),
      danger: true,
    );
    if (!ok) return;
    await SurveyDb.I.deleteSurvey(s.id);
    _load();
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SettingsSheet(settings: widget.settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('appTitle')),
        actions: [
          PopupMenuButton<String>(
            tooltip: context.tr('language'),
            icon: const Icon(Icons.translate_rounded),
            onSelected: widget.settings.setLang,
            itemBuilder: (_) => [
              for (final c in supportedCodes)
                PopupMenuItem<String>(
                  value: c,
                  child: Row(children: [
                    Icon(Icons.check_rounded,
                        color: c == widget.settings.lang ? kMint : Colors.transparent),
                    const SizedBox(width: 8),
                    Text(languageNames[c]!, style: const TextStyle(fontSize: 17)),
                  ]),
                ),
            ],
          ),
          IconButton(
            tooltip: context.tr('surveyorName'),
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const FormBuilderScreen()),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('newSurvey'), style: const TextStyle(fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _surveys.isEmpty
              ? _empty(context)
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: _surveys.length,
                      itemBuilder: (_, i) => _card(context, _surveys[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fact_check_outlined, size: 88, color: kSky),
            const SizedBox(height: 16),
            Text(context.tr('noSurveys'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(context.tr('noSurveysHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Survey s) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(s.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _open(FormBuilderScreen(survey: s));
                  if (v == 'delete') _deleteSurvey(s);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(context.tr('edit'))),
                  PopupMenuItem(value: 'delete', child: Text(context.tr('delete'))),
                ],
              ),
            ]),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Text(
                '${context.trn('responsesCount', s.responseCount)}  ·  ${fmtDate(s.createdAt).substring(0, 10)}',
                style: const TextStyle(fontSize: 15, color: kMuted),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        _open(SurveyScreen(survey: s, settings: widget.settings)),
                    icon: const Icon(Icons.edit_note_rounded, size: 26),
                    label: Text(context.tr('collect')),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _open(ResponsesScreen(survey: s)),
                        icon: const Icon(Icons.list_alt_rounded),
                        label: Text(context.tr('responses')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (btnContext) => OutlinedButton.icon(
                          onPressed: () => exportFlow(btnContext, s),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(context.tr('export')),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
