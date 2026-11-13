import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

class Settings extends ChangeNotifier {
  Settings._(this._prefs, this._lang, this.surveyor);

  final SharedPreferences _prefs;
  String _lang;
  String surveyor;

  String get lang => _lang;

  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    var lang = prefs.getString('lang');
    if (lang == null || !supportedCodes.contains(lang)) {
      final device = PlatformDispatcher.instance.locale.languageCode;
      lang = supportedCodes.contains(device) ? device : 'en';
    }
    return Settings._(prefs, lang, prefs.getString('surveyor') ?? '');
  }

  Future<void> setLang(String code) async {
    _lang = code;
    notifyListeners();
    await _prefs.setString('lang', code);
  }

  Future<void> setSurveyor(String name) async {
    surveyor = name.trim();
    await _prefs.setString('surveyor', surveyor);
  }
}
