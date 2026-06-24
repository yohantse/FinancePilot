import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';
import 'views/main_shell.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize offline-first local database
  await HiveStorage.init();
  
  runApp(
    const ProviderScope(
      child: FinancePilotApp(),
    ),
  );
}

class FinancePilotApp extends StatelessWidget {
  const FinancePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinancePilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
