import 'package:flutter/material.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/fill_demo_data.dart';

import 'features/auth/presentation/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('STEP 1: Flutter initialized');

  try {
    debugPrint('STEP 2: Database initialization started');

    await Db.init();
    // FillDemoData.seedDemoData();
    // await Db.clearAllData();
    // await Db.resetDatabase();

    debugPrint('STEP 3: Database initialized');

  } catch (e, stack) {
    debugPrint('DATABASE ERROR: $e');
    debugPrintStack(stackTrace: stack);
  }

  debugPrint('STEP 4: Running app');

  runApp(const HrmsApp());
}

class HrmsApp extends StatelessWidget {
  const HrmsApp({super.key});

  @override
  Widget build(BuildContext context) {

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.light,
    );
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return MaterialApp(
      title: 'HRMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF4F5FA),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(shape: shape),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(
              scheme.surfaceContainerHighest.withOpacity(0.55)),
          headingTextStyle: TextStyle(
              fontWeight: FontWeight.w700, color: scheme.onSurface),
          headingRowHeight: 48,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 60,
          dividerThickness: 0.6,
        ),
        listTileTheme: ListTileThemeData(shape: shape),
        chipTheme: ChipThemeData(shape: shape),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: shape,
        ),
      ),
      home: const AuthFeaturePage(),
    );
  }
}

