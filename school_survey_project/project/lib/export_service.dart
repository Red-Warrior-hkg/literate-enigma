import 'dart:io';
import 'dart:ui' show Rect;

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db.dart';
import 'l10n.dart';
import 'models.dart';

class ExportService {
  /// Header row + one row per response. Cells are String or num.
  static Future<List<List<Object>>> _table(Survey s, String lang) async {
    final qs = await SurveyDb.I.questions(s.id);
    final rs = await SurveyDb.I.responses(s.id);
    final rows = <List<Object>>[
      <Object>['#', trLang(lang, 'colDate'), trLang(lang, 'colSurveyor'), ...qs.map((q) => q.label)],
    ];
    for (var i = 0; i < rs.length; i++) {
      final r = rs[i];
      rows.add(<Object>[
        i + 1,
        fmtDate(r.createdAt),
        r.surveyor,
        ...qs.map((q) => _cell(q, r.answers[q.id], lang)),
      ]);
    }
    return rows;
  }

  static Object _cell(Question q, dynamic v, String lang) {
    if (v == null) return '';
    if (q.type == QType.number) {
      final n = num.tryParse('$v'.replaceAll(',', '.'));
      if (n != null) return n;
    }
    return answerText(q, v, lang);
  }

  static String _csvField(Object v) {
    final s = '$v';
    if (s.contains(RegExp(r'[;"\r\n]'))) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static Future<File> _tempFile(String title, String ext) async {
    final dir = await getTemporaryDirectory();
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    var name = title.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    if (name.length > 40) name = name.substring(0, 40);
    if (name.isEmpty) name = 'survey';
    final stamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
    return File('${dir.path}/${name}_$stamp.$ext');
  }

  /// UTF-8 with BOM (so Excel shows accents and Arabic correctly), ';' separated.
  static Future<void> exportCsv(Survey s, String lang, Rect? origin) async {
    final rows = await _table(s, lang);
    final sb = StringBuffer('\uFEFF');
    for (final r in rows) {
      sb.write(r.map(_csvField).join(';'));
      sb.write('\r\n');
    }
    final file = await _tempFile(s.title, 'csv');
    await file.writeAsString(sb.toString(), flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: s.title,
      sharePositionOrigin: origin,
    );
  }

  static CellValue _xl(Object v) {
    if (v is int) return IntCellValue(v);
    if (v is num) return DoubleCellValue(v.toDouble());
    return TextCellValue('$v');
  }

  static Future<void> exportXlsx(Survey s, String lang, Rect? origin) async {
    final rows = await _table(s, lang);
    final excel = Excel.createExcel();
    const sheetName = 'Responses';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];
    sheet.isRTL = lang == 'ar';
    for (final r in rows) {
      sheet.appendRow(r.map(_xl).toList());
    }
    final header = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#DCEBFF'),
    );
    for (var c = 0; c < rows.first.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = header;
      sheet.setColumnWidth(c, c == 0 ? 6 : 24);
    }
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Excel encoding failed');
    final file = await _tempFile(s.title, 'xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [
        XFile(file.path,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      ],
      subject: s.title,
      sharePositionOrigin: origin,
    );
  }
}
