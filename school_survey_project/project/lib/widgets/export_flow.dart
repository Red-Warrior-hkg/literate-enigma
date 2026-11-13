import 'package:flutter/material.dart';

import '../db.dart';
import '../export_service.dart';
import '../l10n.dart';
import '../models.dart';

/// Asks for the format, builds the file and opens the system share sheet
/// (save to Files / Drive, send by email or WhatsApp...).
Future<void> exportFlow(BuildContext context, Survey survey) async {
  final messenger = ScaffoldMessenger.of(context);
  final lang = context.lang;
  final emptyMsg = context.tr('nothingToExport');
  final failMsg = context.tr('exportFailed');
  final box = context.findRenderObject() as RenderBox?;
  final origin =
      (box != null && box.hasSize) ? box.localToGlobal(Offset.zero) & box.size : null;

  final n = await SurveyDb.I.count(survey.id);
  if (n == 0) {
    messenger.showSnackBar(SnackBar(content: Text(emptyMsg)));
    return;
  }
  if (!context.mounted) return;

  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(ctx.tr('exportAs'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            leading: const Icon(Icons.grid_on_rounded, size: 30),
            title: Text(ctx.tr('exportExcel'), style: const TextStyle(fontSize: 17)),
            subtitle: Text(ctx.tr('xlsxHint')),
            onTap: () => Navigator.of(ctx).pop('xlsx'),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            leading: const Icon(Icons.description_outlined, size: 30),
            title: Text(ctx.tr('exportCsv'), style: const TextStyle(fontSize: 17)),
            subtitle: Text(ctx.tr('csvHint')),
            onTap: () => Navigator.of(ctx).pop('csv'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null) return;

  try {
    if (choice == 'csv') {
      await ExportService.exportCsv(survey, lang, origin);
    } else {
      await ExportService.exportXlsx(survey, lang, origin);
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
  }
}
