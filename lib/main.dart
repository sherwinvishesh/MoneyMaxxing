import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/welcome_screen.dart';
import 'services/database_helper.dart';
import 'services/recurring_service.dart';
import 'services/background_service.dart';
import 'screens/category_settings_screen.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const bool FORCE_DB_RESET = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Get API key from env
  final apiKey = dotenv.env['GEMINI_API'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception("GEMINI_API is not set in the .env file");
  }

  Gemini.init(apiKey: apiKey);

  if (FORCE_DB_RESET) {
    await DatabaseHelper.instance.resetDatabase();
    debugPrint("Database has been reset by force");
  } else {
    await DatabaseHelper.instance.ensureSampleDataExists();
    debugPrint("Sample data checked without affecting user data");

    final radicalDeletions =
        await DatabaseHelper.instance.radicalCleanupDuplicateIncomes();
    debugPrint("Radical cleanup removed $radicalDeletions duplicate incomes");

    final feb24 = DateTime(2025, 2, 24);
    final feb24Deletions =
        await DatabaseHelper.instance.removeAllDuplicateIncomesForDate(feb24);
    debugPrint("Feb 24 cleanup removed $feb24Deletions duplicate incomes");

    final deletedIncomes =
        await DatabaseHelper.instance.cleanupDuplicateIncomes();
    final deletedExpenditures =
        await DatabaseHelper.instance.cleanupDuplicateExpenditures();
    final deletedExactDuplicates = await DatabaseHelper.instance
        .cleanupDuplicateIncomesWithSameTimestamp();
    final deletedSameDateDuplicates =
        await DatabaseHelper.instance.cleanupDuplicateIncomesWithSameDate();

    debugPrint(
        "Standard cleanup removed $deletedIncomes regular duplicates, $deletedExactDuplicates exact timestamp duplicates, and $deletedSameDateDuplicates same-date duplicates");
    debugPrint("Cleanup removed $deletedExpenditures duplicate expenditures");
  }

  await RecurringService.instance.checkAndProcessRecurring();
  BackgroundService.instance.startRecurringCheck();

  runApp(const MoneyMaxxingApp());
}
