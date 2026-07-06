import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petpal/core/services/notification_service.dart';

import 'package:petpal/firebase_options.dart';
import 'package:petpal/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts/ — never fetch at runtime, so
  // first paint is correct even with no network.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final path in [
      'assets/google_fonts/OFL_Heebo.txt',
      'assets/google_fonts/OFL_FrankRuhlLibre.txt',
    ]) {
      yield LicenseEntryWithLineBreaks(
        ['google_fonts'],
        await rootBundle.loadString(path),
      );
    }
  });
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: PetPalApp(),
    ),
  );
}
