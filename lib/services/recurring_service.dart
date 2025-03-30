// lib/services/recurring_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expenditure.dart';
import 'database_helper.dart';
import '../models/income.dart';
import '../models/financial_transaction.dart';

class RecurringService {
  static final RecurringService instance = RecurringService._init();
  RecurringService._init();

  // Key for storing the last check timestamp
  static const String _lastCheckKey = 'last_recurring_check_time';

  // Process a newly created recurring transaction - called when a recurring transaction is first created
  Future<void> processNewRecurringTransaction(
      Expenditure recurringExpense) async {
    debugPrint(
        'Processing new recurring transaction: ${recurringExpense.name}');

    // Safety check - if there's no ID, we can't create instances
    if (recurringExpense.id == null) {
      debugPrint('Cannot process recurring transaction without an ID');
      return;
    }

    // Get the start date (original transaction date)
    final startDate = recurringExpense.dateTime;

    // Get current date without time component
    final now = DateTime.now();

    // Create past instances from start date to current date
    if (startDate.isBefore(now)) {
      debugPrint(
          'Creating past instances from ${startDate.toString().substring(0, 10)} to ${now.toString().substring(0, 10)}');

      // Get all dates from start date to now according to recurrence pattern
      await _createPastInstances(recurringExpense, startDate, now);
    }
  }

// In recurring_service.dart, modify checkAndProcessRecurring:

  Future<void> checkAndProcessRecurring({bool forceProcess = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Get last check time or default to now minus 1 day if first run
    final lastCheckTimeStr = prefs.getString(_lastCheckKey);
    final lastCheckTime = lastCheckTimeStr != null
        ? DateTime.parse(lastCheckTimeStr)
        : now.subtract(const Duration(days: 1));

    // Skip if recently checked, unless forceProcess is true
    if (!forceProcess && now.difference(lastCheckTime).inMinutes < 1) {
      debugPrint(
          'Skipping recurring check: last check was less than a minute ago');
      return;
    }

    debugPrint('Checking for recurring transactions since $lastCheckTime');

    // Process recurring expenses and incomes
    await _processRecurringExpenses(lastCheckTime, now);
    await _processRecurringIncomes(lastCheckTime, now);

    // Always update last check time
    await prefs.setString(_lastCheckKey, now.toIso8601String());
    debugPrint('Updated last recurring check time to $now');
  }

// Add a helper method to get the next occurrence date
  DateTime? getNextOccurrenceFromNow(Income recurringIncome) {
    final now = DateTime.now();
    return _getNextOccurrenceForIncome(recurringIncome, now);
  }

// Same for expenditures
  DateTime? getNextExpenditureOccurrenceFromNow(
      Expenditure recurringExpenditure) {
    final now = DateTime.now();
    return _getNextOccurrence(recurringExpenditure, now);
  }

  Future<void> processNewRecurringIncome(Income recurringIncome) async {
    debugPrint('Processing new recurring income: ${recurringIncome.name}');

    // Safety check - if there's no ID, we can't create instances
    if (recurringIncome.id == null) {
      debugPrint('Cannot process recurring income without an ID');
      return;
    }

    // IMPORTANT: First do a cleanup of any potential duplicates
    await _cleanupDuplicatesForIncome(recurringIncome);

    // Get the start date (original transaction date)
    final startDate = recurringIncome.dateTime;

    // Get current date without time component
    final now = DateTime.now();

    // Create future instances from day after start date to current date
    final dayAfterStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).add(const Duration(days: 1));

    // Only process if there are days between the start and now
    if (dayAfterStart.isBefore(now)) {
      debugPrint(
          'Creating future instances from ${dayAfterStart.toString().substring(0, 10)} to ${now.toString().substring(0, 10)}');

      // Get all dates from after start date to now according to recurrence pattern
      await _createFutureIncomeInstances(recurringIncome, dayAfterStart, now);
    }
  }

  Future<void> _processRecurringIncomes(DateTime start, DateTime end) async {
    // Get all recurring incomes
    final incomes = await DatabaseHelper.instance.getRecurringIncomes();

    for (final income in incomes) {
      // Skip if this is a child instance, not the parent recurring definition
      if (income.parentRecurringId != null) continue;

      // Skip if there's no ID
      if (income.id == null) continue;

      // Check if we need to create new instances based on recurrence pattern
      await _createDueIncomeInstances(income, start, end);
    }
  }

// Create instances of recurring incomes that are due
  Future<void> _createDueIncomeInstances(
      Income recurringIncome, DateTime start, DateTime end) async {
    // If it's not recurring or it's ended, skip
    if (!recurringIncome.isRecurring) return;
    if (recurringIncome.endOption == 'Custom' &&
        recurringIncome.endDate != null &&
        recurringIncome.endDate!.isBefore(start)) return;

    // Get the next occurrence date after the start date
    DateTime? nextDate = _getNextOccurrenceForIncome(recurringIncome, start);
    if (nextDate == null) return;

    // Create instances for all occurrences within the time range
    while (nextDate != null && nextDate.isBefore(end)) {
      await _createIncomeInstance(recurringIncome, nextDate);
      nextDate = _getNextOccurrenceForIncome(recurringIncome, nextDate);

      // If it's ended, stop creating instances
      if (recurringIncome.endOption == 'Custom' &&
          recurringIncome.endDate != null &&
          nextDate != null &&
          nextDate.isAfter(recurringIncome.endDate!)) {
        break;
      }
    }
  }

  Future<List<FinancialTransaction>> processAndGetNewTransactions() async {
    final now = DateTime.now();

    // Process any pending recurring transactions first
    await checkAndProcessRecurring(forceProcess: true);

    // Then get the latest transactions
    final latestTransactions =
        await DatabaseHelper.instance.getLatestTransactions(20);

    return latestTransactions;
  }

  Future<void> _createPastIncomeInstances(
      Income recurringIncome, DateTime startDate, DateTime endDate) async {
    // If it's not recurring or it's ended, skip
    if (!recurringIncome.isRecurring) return;
    if (recurringIncome.endOption == 'Custom' &&
        recurringIncome.endDate != null &&
        recurringIncome.endDate!.isBefore(startDate)) return;

    // Make sure we have an ID
    if (recurringIncome.id == null) {
      debugPrint('Cannot create instances for recurring income without ID');
      return;
    }

    // Get all occurrences from start date to end date
    List<DateTime> occurrences = [];
    DateTime? currentDate = startDate;

    // First, check if an instance for the original date already exists
    final existingOriginalInstances = await DatabaseHelper.instance
        .getIncomeInstancesForDate(recurringIncome.id!, startDate);

    // Check if the original instance exists with exactly the same time
    bool originalInstanceExists = false;
    for (var existing in existingOriginalInstances) {
      if (existing.dateTime.hour == startDate.hour &&
          existing.dateTime.minute == startDate.minute) {
        originalInstanceExists = true;
        break;
      }
    }

    // Only add the first occurrence (start date) if it doesn't exist already
    if (!originalInstanceExists) {
      occurrences.add(startDate);
      debugPrint(
          'Adding original date ${startDate.toString()} to occurrences - no instance exists yet');
    } else {
      debugPrint('Original date instance already exists, skipping');
    }

    // Get next occurrences until we reach the end date
    currentDate = _getNextOccurrenceForIncome(recurringIncome, currentDate);
    while (currentDate != null && !currentDate.isAfter(endDate)) {
      occurrences.add(currentDate);
      currentDate = _getNextOccurrenceForIncome(recurringIncome, currentDate);

      // If it's ended, stop creating instances
      if (recurringIncome.endOption == 'Custom' &&
          recurringIncome.endDate != null &&
          currentDate != null &&
          currentDate.isAfter(recurringIncome.endDate!)) {
        break;
      }
    }

    // Create instances for each date
    int created = 0;
    for (final date in occurrences) {
      try {
        await _createIncomeInstance(recurringIncome, date);
        created++;
      } catch (e) {
        debugPrint('Error creating recurring income instance: $e');
      }
    }

    debugPrint('Created $created past instances for ${recurringIncome.name}');
  }
// In lib/services/recurring_service.dart, update the _createIncomeInstance method:

  Future<void> _createIncomeInstance(
      Income recurringIncome, DateTime instanceDate) async {
    try {
      // Make sure we have an ID to use as parent ID
      if (recurringIncome.id == null) {
        throw Exception(
            'Cannot create instance for recurring income without ID');
      }

      // CRITICAL: Skip if this is the same day as the original recurring definition
      if (instanceDate.year == recurringIncome.dateTime.year &&
          instanceDate.month == recurringIncome.dateTime.month &&
          instanceDate.day == recurringIncome.dateTime.day) {
        debugPrint(
            'Skipping creation of instance for original date: ${instanceDate.toString().substring(0, 10)}');
        return;
      }

      // Check if an instance already exists for this date (avoid duplicates)
      // Use a more precise date check (including hour and minute)
      final existingInstances = await DatabaseHelper.instance
          .getIncomeInstancesForDate(recurringIncome.id!, instanceDate);

      bool instanceExists = false;
      for (var existing in existingInstances) {
        // Check if hours and minutes match as well to prevent duplicates
        if (existing.dateTime.hour == instanceDate.hour &&
            existing.dateTime.minute == instanceDate.minute) {
          instanceExists = true;
          break;
        }
      }

      if (instanceExists) {
        debugPrint(
            'Instance already exists for ${recurringIncome.name} on $instanceDate');
        return;
      }

      // Create a new instance with the recurring income as parent
      final newInstance = Income(
        name: recurringIncome.name,
        dateTime: instanceDate,
        amount: recurringIncome.amount,
        isRecurring: false, // This is an instance, not a recurring definition
        parentRecurringId: recurringIncome.id,
        notes: recurringIncome.notes,
      );

      // Save to database
      final id = await DatabaseHelper.instance.insertIncome(newInstance);
      debugPrint(
          'Created recurring income instance #$id for ${recurringIncome.name} on $instanceDate');
    } catch (e) {
      debugPrint('Error creating recurring income instance: $e');
      rethrow;
    }
  }

  // Process recurring expenses for regular checks
  Future<void> _processRecurringExpenses(DateTime start, DateTime end) async {
    // Get all recurring expenses
    final expenses = await DatabaseHelper.instance.getRecurringExpenditures();

    for (final expense in expenses) {
      // Skip if this is a child instance, not the parent recurring definition
      if (expense.parentRecurringId != null) continue;

      // Skip if there's no ID
      if (expense.id == null) continue;

      // Check if we need to create new instances based on recurrence pattern
      await _createDueExpenseInstances(expense, start, end);
    }
  }

  // Create past instances for a new recurring transaction
  Future<void> _createPastInstances(Expenditure recurringExpense,
      DateTime startDate, DateTime endDate) async {
    // If it's not recurring or it's ended, skip
    if (!recurringExpense.isRecurring) return;
    if (recurringExpense.endOption == 'Custom' &&
        recurringExpense.endDate != null &&
        recurringExpense.endDate!.isBefore(startDate)) return;

    // Make sure we have an ID
    if (recurringExpense.id == null) {
      debugPrint('Cannot create instances for recurring expense without ID');
      return;
    }

    // Get all occurrences from start date to end date
    List<DateTime> occurrences = [];
    DateTime? currentDate = startDate;

    // First, check if an instance for the original date already exists
    final existingOriginalInstances = await DatabaseHelper.instance
        .getExpenditureInstancesForDate(recurringExpense.id!, startDate);

    // Check if the original instance exists with exactly the same time
    bool originalInstanceExists = false;
    for (var existing in existingOriginalInstances) {
      if (existing.dateTime.hour == startDate.hour &&
          existing.dateTime.minute == startDate.minute) {
        originalInstanceExists = true;
        break;
      }
    }

    // Only add the first occurrence (start date) if it doesn't exist already
    // This handles cases where no instance was created for the original date
    if (!originalInstanceExists) {
      occurrences.add(startDate);
      debugPrint(
          'Adding original date ${startDate.toString()} to occurrences - no instance exists yet');
    } else {
      debugPrint('Original date instance already exists, skipping');
    }

    // Get next occurrences until we reach the end date
    currentDate = _getNextOccurrence(recurringExpense, currentDate);
    while (currentDate != null && !currentDate.isAfter(endDate)) {
      occurrences.add(currentDate);
      currentDate = _getNextOccurrence(recurringExpense, currentDate);

      // If it's ended, stop creating instances
      if (recurringExpense.endOption == 'Custom' &&
          recurringExpense.endDate != null &&
          currentDate != null &&
          currentDate.isAfter(recurringExpense.endDate!)) {
        break;
      }
    }

    // Create instances for each date
    int created = 0;
    for (final date in occurrences) {
      try {
        await _createExpenseInstance(recurringExpense, date);
        created++;
      } catch (e) {
        debugPrint('Error creating recurring instance: $e');
      }
    }

    debugPrint('Created $created past instances for ${recurringExpense.name}');
  }

  // Create instances of recurring expenses that are due in the given time range
  Future<void> _createDueExpenseInstances(
      Expenditure recurringExpense, DateTime start, DateTime end) async {
    // If it's not recurring or it's ended, skip
    if (!recurringExpense.isRecurring) return;
    if (recurringExpense.endOption == 'Custom' &&
        recurringExpense.endDate != null &&
        recurringExpense.endDate!.isBefore(start)) return;

    // Get the next occurrence date after the start date
    DateTime? nextDate = _getNextOccurrence(recurringExpense, start);
    if (nextDate == null) return;

    // Create instances for all occurrences within the time range
    while (nextDate != null && nextDate.isBefore(end)) {
      await _createExpenseInstance(recurringExpense, nextDate);
      nextDate = _getNextOccurrence(recurringExpense, nextDate);

      // If it's ended, stop creating instances
      if (recurringExpense.endOption == 'Custom' &&
          recurringExpense.endDate != null &&
          nextDate != null &&
          nextDate.isAfter(recurringExpense.endDate!)) {
        break;
      }
    }
  }

  // Create a single instance of a recurring expense
  Future<void> _createExpenseInstance(
      Expenditure recurringExpense, DateTime instanceDate) async {
    try {
      // Make sure we have an ID to use as parent ID
      if (recurringExpense.id == null) {
        throw Exception(
            'Cannot create instance for recurring expense without ID');
      }

      // Check if an instance already exists for this date (avoid duplicates)
      final existingInstances = await DatabaseHelper.instance
          .getExpenditureInstancesForDate(recurringExpense.id!, instanceDate);

      if (existingInstances.isNotEmpty) {
        debugPrint(
            'Instance already exists for ${recurringExpense.name} on $instanceDate');
        return;
      }

      // Create a new instance with the recurring expense as parent
      final newInstance = Expenditure(
        name: recurringExpense.name,
        category: recurringExpense.category,
        dateTime: instanceDate,
        cost: recurringExpense.cost,
        isRecurring: false, // This is an instance, not a recurring definition
        parentRecurringId: recurringExpense.id,
        notes: recurringExpense.notes,
      );

      // Save to database
      final id = await DatabaseHelper.instance.insertExpenditure(newInstance);
      debugPrint(
          'Created recurring instance #$id for ${recurringExpense.name} on $instanceDate');
    } catch (e) {
      debugPrint('Error creating recurring instance: $e');
      rethrow; // Rethrow to allow caller to handle or log
    }
  }

  // Get the next occurrence date based on the recurrence pattern
  DateTime? _getNextOccurrence(
      Expenditure recurringExpense, DateTime afterDate) {
    // Start from the original transaction date
    final baseDate = recurringExpense.dateTime;

    // If the base date is after the reference date, it's the next occurrence
    if (baseDate.isAfter(afterDate)) return baseDate;

    // Calculate how many intervals have passed since the base date
    int intervalsPassed;
    DateTime nextDate;

    switch (recurringExpense.repeatFrequency) {
      case 'Day':
        intervalsPassed = afterDate.difference(baseDate).inDays;
        nextDate = baseDate.add(Duration(days: intervalsPassed + 1));
        break;

      case 'Week':
        intervalsPassed = afterDate.difference(baseDate).inDays ~/ 7;
        nextDate = baseDate.add(Duration(days: (intervalsPassed + 1) * 7));
        break;

      case 'Bi-weekly':
        intervalsPassed = afterDate.difference(baseDate).inDays ~/ 14;
        nextDate = baseDate.add(Duration(days: (intervalsPassed + 1) * 14));
        break;

      case 'Month':
        // Calculate months passed
        int monthsPassed = (afterDate.year - baseDate.year) * 12 +
            (afterDate.month - baseDate.month);

        // If we're past the day of month, add one more month
        if (afterDate.day >= baseDate.day) monthsPassed++;

        // Create next date with same day of month
        int year = baseDate.year + (baseDate.month + monthsPassed - 1) ~/ 12;
        int month = (baseDate.month + monthsPassed - 1) % 12 + 1;
        int day = baseDate.day;

        // Handle day overflow (e.g., Jan 31 -> Feb 28)
        while (true) {
          try {
            nextDate = DateTime(year, month, day, baseDate.hour,
                baseDate.minute, baseDate.second);
            break;
          } catch (_) {
            // If invalid date (e.g., Feb 30), reduce day by 1
            day--;
          }
        }
        break;

      default:
        // Unknown frequency, default to monthly
        int monthsPassed = (afterDate.year - baseDate.year) * 12 +
            (afterDate.month - baseDate.month);
        if (afterDate.day >= baseDate.day) monthsPassed++;

        int year = baseDate.year + (baseDate.month + monthsPassed - 1) ~/ 12;
        int month = (baseDate.month + monthsPassed - 1) % 12 + 1;
        nextDate = DateTime(year, month, baseDate.day, baseDate.hour,
            baseDate.minute, baseDate.second);
    }

    // Check if we've reached the end date
    if (recurringExpense.endOption == 'Custom' &&
        recurringExpense.endDate != null &&
        nextDate.isAfter(recurringExpense.endDate!)) {
      return null;
    }

    return nextDate;
  }

  // Get the next occurrence date based on the recurrence pattern for Income
  DateTime? _getNextOccurrenceForIncome(
      Income recurringIncome, DateTime afterDate) {
    // Start from the original transaction date
    final baseDate = recurringIncome.dateTime;

    // If the base date is after the reference date, it's the next occurrence
    if (baseDate.isAfter(afterDate)) return baseDate;

    // Calculate how many intervals have passed since the base date
    int intervalsPassed;
    DateTime nextDate;

    switch (recurringIncome.repeatFrequency) {
      case 'Day':
        intervalsPassed = afterDate.difference(baseDate).inDays;
        nextDate = baseDate.add(Duration(days: intervalsPassed + 1));
        break;

      case 'Week':
        intervalsPassed = afterDate.difference(baseDate).inDays ~/ 7;
        nextDate = baseDate.add(Duration(days: (intervalsPassed + 1) * 7));
        break;

      case 'Bi-weekly':
        intervalsPassed = afterDate.difference(baseDate).inDays ~/ 14;
        nextDate = baseDate.add(Duration(days: (intervalsPassed + 1) * 14));
        break;

      case 'Month':
        // Calculate months passed
        int monthsPassed = (afterDate.year - baseDate.year) * 12 +
            (afterDate.month - baseDate.month);

        // If we're past the day of month, add one more month
        if (afterDate.day >= baseDate.day) monthsPassed++;

        // Create next date with same day of month
        int year = baseDate.year + (baseDate.month + monthsPassed - 1) ~/ 12;
        int month = (baseDate.month + monthsPassed - 1) % 12 + 1;
        int day = baseDate.day;

        // Handle day overflow (e.g., Jan 31 -> Feb 28)
        while (true) {
          try {
            nextDate = DateTime(year, month, day, baseDate.hour,
                baseDate.minute, baseDate.second);
            break;
          } catch (_) {
            // If invalid date (e.g., Feb 30), reduce day by 1
            day--;
          }
        }
        break;

      default:
        // Unknown frequency, default to monthly
        int monthsPassed = (afterDate.year - baseDate.year) * 12 +
            (afterDate.month - baseDate.month);
        if (afterDate.day >= baseDate.day) monthsPassed++;

        int year = baseDate.year + (baseDate.month + monthsPassed - 1) ~/ 12;
        int month = (baseDate.month + monthsPassed - 1) % 12 + 1;
        nextDate = DateTime(year, month, baseDate.day, baseDate.hour,
            baseDate.minute, baseDate.second);
    }

    // Check if we've reached the end date
    if (recurringIncome.endOption == 'Custom' &&
        recurringIncome.endDate != null &&
        nextDate.isAfter(recurringIncome.endDate!)) {
      return null;
    }

    return nextDate;
  }

  Future<void> _cleanupDuplicatesForIncome(Income recurringIncome) async {
    if (recurringIncome.id == null) return;

    final db = await DatabaseHelper.instance.database;
    final allInstances = await DatabaseHelper.instance
        .getRecurringIncomeInstances(recurringIncome.id!);

    // Group by date to find duplicates
    final Map<String, List<Income>> instancesByDate = {};

    for (final instance in allInstances) {
      // Create a key based on date only (YYYY-MM-DD)
      final dateKey = instance.dateTime.toString().substring(0, 10);

      if (instancesByDate.containsKey(dateKey)) {
        instancesByDate[dateKey]!.add(instance);
      } else {
        instancesByDate[dateKey] = [instance];
      }
    }

    // Delete duplicates for each date
    int deleted = 0;
    for (final entries in instancesByDate.values) {
      if (entries.length > 1) {
        // Sort by ID (ascending)
        entries.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

        // Keep the first entry, delete the rest
        for (int i = 1; i < entries.length; i++) {
          if (entries[i].id != null) {
            await db
                .delete('income', where: 'id = ?', whereArgs: [entries[i].id]);
            deleted++;
            debugPrint(
                'Deleted duplicate income instance: ${entries[i].name} on ${entries[i].dateTime} (ID: ${entries[i].id})');
          }
        }
      }
    }

    if (deleted > 0) {
      debugPrint(
          'Cleaned up $deleted duplicate instances for income ${recurringIncome.name}');
    }
  }

  Future<void> _createFutureIncomeInstances(
      Income recurringIncome, DateTime startDate, DateTime endDate) async {
    // If it's not recurring or it's ended, skip
    if (!recurringIncome.isRecurring) return;
    if (recurringIncome.endOption == 'Custom' &&
        recurringIncome.endDate != null &&
        recurringIncome.endDate!.isBefore(startDate)) return;

    // Make sure we have an ID
    if (recurringIncome.id == null) {
      debugPrint('Cannot create instances for recurring income without ID');
      return;
    }

    // Get all occurrences from start date to end date
    List<DateTime> occurrences = [];

    // IMPORTANT: Start with the day AFTER the original date
    DateTime? currentDate = _getNextOccurrenceForIncome(
        recurringIncome, startDate.subtract(const Duration(days: 1)));

    // Get all occurrences until we reach the end date
    while (currentDate != null && !currentDate.isAfter(endDate)) {
      // Extra check: Make sure this is not the same day as the start date
      if (currentDate.year != recurringIncome.dateTime.year ||
          currentDate.month != recurringIncome.dateTime.month ||
          currentDate.day != recurringIncome.dateTime.day) {
        occurrences.add(currentDate);
      }

      currentDate = _getNextOccurrenceForIncome(recurringIncome, currentDate);

      // If it's ended, stop creating instances
      if (recurringIncome.endOption == 'Custom' &&
          recurringIncome.endDate != null &&
          currentDate != null &&
          currentDate.isAfter(recurringIncome.endDate!)) {
        break;
      }
    }

    // Create instances for each date
    int created = 0;
    for (final date in occurrences) {
      try {
        // Skip if it's the same day as the original
        if (date.year == recurringIncome.dateTime.year &&
            date.month == recurringIncome.dateTime.month &&
            date.day == recurringIncome.dateTime.day) {
          debugPrint(
              'Skipping instance for the original date: ${date.toString()}');
          continue;
        }

        // Check if instance already exists for this date
        final existingInstances = await DatabaseHelper.instance
            .getIncomeInstancesForDate(recurringIncome.id!, date);

        if (existingInstances.isNotEmpty) {
          debugPrint(
              'Instance already exists for date: ${date.toString().substring(0, 10)}');
          continue;
        }

        await _createIncomeInstance(recurringIncome, date);
        created++;
      } catch (e) {
        debugPrint('Error creating recurring income instance: $e');
      }
    }

    debugPrint('Created $created future instances for ${recurringIncome.name}');
  }

  Future<void> forceProcessRecurringIncome(Income recurringIncome) async {
    if (!recurringIncome.isRecurring || recurringIncome.id == null) {
      return;
    }

    final now = DateTime.now();

    // Get next occurrence date
    DateTime? nextDate = getNextOccurrenceFromNow(recurringIncome);

    // If there's a next occurrence, create it
    if (nextDate != null &&
        !nextDate.isAfter(now.add(const Duration(minutes: 15)))) {
      // Create this instance
      await _createIncomeInstance(recurringIncome, nextDate);
      debugPrint('Force created upcoming income instance at $nextDate');
    }
  }

// Add this method to force immediate processing of a specific recurring expenditure
  Future<void> forceProcessRecurringExpenditure(
      Expenditure recurringExpenditure) async {
    if (!recurringExpenditure.isRecurring || recurringExpenditure.id == null) {
      return;
    }

    final now = DateTime.now();

    // Get next occurrence date
    DateTime? nextDate =
        getNextExpenditureOccurrenceFromNow(recurringExpenditure);

    // If there's a next occurrence and it's due within 15 minutes, create it
    if (nextDate != null &&
        !nextDate.isAfter(now.add(const Duration(minutes: 15)))) {
      // Create this instance
      await _createExpenseInstance(recurringExpenditure, nextDate);
      debugPrint('Force created upcoming expense instance at $nextDate');
    }
  }
}
