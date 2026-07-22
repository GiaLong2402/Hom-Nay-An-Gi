import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/app_settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase init failed: $error\n$stackTrace');
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    bootstrapAppSettings = await AppSettings.load(prefs);
  } catch (error, stackTrace) {
    debugPrint('Settings load failed: $error\n$stackTrace');
  }

  runApp(
    const ProviderScope(
      child: HomNayAnGiApp(),
    ),
  );
}

class HomNayAnGiApp extends ConsumerWidget {
  const HomNayAnGiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: 'Hôm Nay Ăn Gì?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const SplashScreen(),
    );
  }
}
