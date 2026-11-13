import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n.dart';
import '../models.dart';
import '../theme.dart';

/// Bottom sheet to create or edit one question. Pops a [Question].
class QuestionEditor extends StatefulWidget {
  const QuestionEditor({super.key, this.initial});

  final Question? initial;

  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late final TextEditingController _label;
  late QType _type;
  late bool _required;
  final List<TextEditingController> _opts = [];
  String? _labelError;
  String? _optError;

  @override
  void initState() {
    super.initState();
    final q = widget.initial;
    _label = TextEditingController(text: q?.label ?? '');
    _type = q?.type ?? QType.yesNo;
    _required = q?.isRequired ?? false;
    for (final o in q?.options ?? const <String>[]) {
      _opts.add(TextEditingController(text: o));
    }
    if (_type.hasOptions && _opts.isEmpty) _seedOptions();
  }

  void _seedOptions() {
    _opts.add(TextEditingController());
    _opts.add(TextEditingController());
  }

  @override
  void dispose() {
    _label.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final label = _label.text.trim();
    final options = <String>[];
    if (_type.hasOptions) {
      for (final c in _opts) {
        final t = c.text.trim();
        if (t.isNotEmpty && !options.contains(t)) options.add(t);
      }
    }
    setState(() {
      _labelError = label.isEmpty ? context.tr('questionRequired') : null;
      _optError = (_type.hasOptions && options.length < 2) ? context.tr('needTwoOptions') : null;
    });
    if (_labelError != null || _optError != null) return;
    Navigator.of(context).pop(Question(
      id: widget.initial?.id ?? const Uuid().v4(),
      label: label,
      type: _type,
      isRequired: _required,
      options: options,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr(editing ? 'editQuestion' : 'addQuestion'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              autofocus: !editing,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: context.tr('questionText'),
                errorText: _labelError,
              ),
            ),
            const SizedBox(height: 20),
            Text(context.tr('questionType'),
                style: const TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in QType.values)
                ChoiceChip(
                  label: Text(context.tr(t.labelKey), style: const TextStyle(fontSize: 16)),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  selected: _type == t,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _type = t;
                    if (t.hasOptions && _opts.isEmpty) _seedOptions();
                    _optError = null;
                  }),
                ),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('required'), style: const TextStyle(fontSize: 17)),
              value: _required,
              onChanged: (v) => setState(() => _required = v),
            ),
            if (_type.hasOptions) ...[
              const SizedBox(height: 8),
              Text(context.tr('options'),
                  style: const TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (var i = 0; i < _opts.length; i++)
                Padding(
                  key: ObjectKey(_opts[i]),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _opts[i],
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 17),
                        decoration:
                            InputDecoration(hintText: '${context.tr('optionHint')} ${i + 1}'),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('delete'),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _opts.length > 1
                          ? () {
                              final removed = _opts[i];
                              setState(() => _opts.removeAt(i));
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) => removed.dispose());
                            }
                          : null,
                    ),
                  ]),
                ),
              if (_optError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_optError!, style: const TextStyle(color: kDanger)),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => _opts.add(TextEditingController())),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.tr('addOption')),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(context.tr(editing ? 'save' : 'add')),
            ),
          ],
        ),
      ),
    );
  }
}
