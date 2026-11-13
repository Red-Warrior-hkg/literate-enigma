import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../models.dart';
import '../theme.dart';

/// Renders any question type with large touch targets.
class QuestionField extends StatelessWidget {
  const QuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    this.controller,
    this.error,
  });

  final Question question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final TextEditingController? controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: error != null ? kDanger : kBorder, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: question.label,
                children: [
                  if (question.isRequired)
                    const TextSpan(text: ' *', style: TextStyle(color: kDanger)),
                ],
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kInk),
            ),
            const SizedBox(height: 14),
            _input(context),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error!, style: const TextStyle(color: kDanger, fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String stored) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 17)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      selected: value == stored,
      showCheckmark: false,
      // Tapping the selected chip again clears it (useful for optional questions).
      onSelected: (_) => onChanged(value == stored ? null : stored),
    );
  }

  Widget _input(BuildContext context) {
    switch (question.type) {
      case QType.yesNo:
        return Wrap(spacing: 12, runSpacing: 12, children: [
          _chip(context, context.tr('yes'), 'yes'),
          _chip(context, context.tr('no'), 'no'),
        ]);
      case QType.singleChoice:
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final o in question.options) _chip(context, o, o)],
        );
      case QType.multiChoice:
        final selected = List<String>.from((value as List?) ?? const <String>[]);
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final o in question.options)
            FilterChip(
              label: Text(o, style: const TextStyle(fontSize: 17)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              selected: selected.contains(o),
              onSelected: (on) {
                final next = List<String>.from(selected);
                if (on) {
                  next.add(o);
                } else {
                  next.remove(o);
                }
                onChanged(next);
              },
            ),
        ]);
      case QType.dropdown:
        return InputDecorator(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: question.options.contains(value) ? value as String : null,
              isExpanded: true,
              hint: Text(context.tr('select')),
              style: const TextStyle(fontSize: 18, color: kInk),
              borderRadius: BorderRadius.circular(16),
              items: [
                for (final o in question.options)
                  DropdownMenuItem<String>(value: o, child: Text(o)),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      case QType.number:
        return TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]'))],
          style: const TextStyle(fontSize: 20),
          onChanged: onChanged,
        );
      case QType.text:
        return TextField(
          controller: controller,
          minLines: 2,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 18),
          onChanged: onChanged,
        );
    }
  }
}
