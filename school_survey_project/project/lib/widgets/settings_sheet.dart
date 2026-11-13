import 'package:flutter/material.dart';

import '../l10n.dart';
import '../settings.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.settings});

  final Settings settings;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.settings.surveyor);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('surveyorName'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(hintText: context.tr('surveyorHint')),
            onChanged: widget.settings.setSurveyor,
            onSubmitted: (_) => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('done')),
          ),
        ],
      ),
    );
  }
}
