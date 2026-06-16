import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/dashboard_page.dart';
import '../state/sign_speak_controller.dart';
import '../theme/app_theme.dart';

class SignSpeakApp extends ConsumerWidget {
  const SignSpeakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(
      signSpeakControllerProvider.select((state) => state.isDarkMode),
    );

    return MaterialApp(
      title: 'Sign Speak AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const DashboardPage(),
    );
  }
}
