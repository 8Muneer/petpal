import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/router/app_router.dart';

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PetPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      // The app's UI copy is Hebrew — pin the locale so every screen (and
      // every Material widget: dialogs, pickers, tooltips) renders RTL
      // consistently regardless of the device language.
      locale: const Locale('he'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he'),
        Locale('en'),
      ],
    );
  }
}
