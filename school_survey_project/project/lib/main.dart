import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n.dart';
import 'screens/home_screen.dart';
import 'settings.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  runApp(SurveyApp(settings: settings));
}

class SurveyApp extends StatelessWidget {
  const SurveyApp({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (c) => c.tr('appTitle'),
        theme: buildTheme(),
        // Arabic automatically switches the whole UI to right-to-left.
        locale: Locale(settings.lang),
        supportedLocales: supportedCodes.map((c) => Locale(c)).toList(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomeScreen(settings: settings),
      ),
    );
  }
}
