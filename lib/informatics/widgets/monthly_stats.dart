// lib/informatics/widgets/monthly_stats.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/budget_data_service.dart';
import '../services/daily_purchase_rate_service.dart';
import '../../services/database_helper.dart';
import '../../services/currency_service.dart';

class MonthlyStats extends StatelessWidget {
  final double
      todaysExpense; // Changed from lastPurchaseAmount to todaysExpense
  final double dailyPurchaseRate;
  final double budgetCoverage;
  final bool showTBD;

  const MonthlyStats({
    super.key,
    required this.todaysExpense, // Updated parameter name
    required this.dailyPurchaseRate,
    required this.budgetCoverage,
    this.showTBD = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(
          title: 'Today\'s\nExpense', // Changed title
          value: '\$${todaysExpense.toStringAsFixed(2)}',
          icon: Icons.today, // Changed icon from shopping_cart to today
          iconColor: Colors.blue,
        ),
        _buildStatCard(
          title: 'Daily\nPurchase Rate',
          value:
              showTBD ? '\$TBD' : '\$${dailyPurchaseRate.toStringAsFixed(2)}',
          icon: Icons.show_chart,
          iconColor: Colors.green,
        ),
        _buildStatCard(
          title: 'Budget\nCoverage',
          value: '${budgetCoverage.toStringAsFixed(1)}%',
          icon: Icons.account_balance_wallet,
          iconColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    // Handle values that start with $ which need to be replaced with the current currency
    if (value.startsWith('\$')) {
      final amountString = value.substring(1); // Remove the $ symbol

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: CurrencyService.instance.getCurrencySymbol(),
                builder: (context, snapshot) {
                  final symbol = snapshot.data ?? '\$';
                  return Text(
                    '$symbol$amountString',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // For non-currency values (like percentages), keep the original implementation
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class MonthlyStatsLoader extends StatefulWidget {
  final String timeString;
  final int monthOffset;

  const MonthlyStatsLoader({
    super.key,
    required this.timeString,
    this.monthOffset = 0,
  });

  @override
  MonthlyStatsLoaderState createState() => MonthlyStatsLoaderState();
}

class MonthlyStatsLoaderState extends State<MonthlyStatsLoader> {
  double _todaysExpense = 0; // Changed from _lastPurchaseAmount
  double _dailyPurchaseRate = 0;
  double _budgetCoverage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Update to handle month changes
  @override
  void didUpdateWidget(MonthlyStatsLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.monthOffset != oldWidget.monthOffset) {
      refreshData();
    }
  }

  Future<void> refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
      await _loadData();
    }
  }

  // Calculate the date range for a given offset
  Future<Map<String, dynamic>> _getDateRangeForOffset(int offset) async {
    // Get month settings to determine the date range
    final monthSettings = await DatabaseHelper.instance.getMonthSettings();

    // Calculate the base date (today with offset)
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month + offset, now.day);

    DateTime startDate;
    DateTime endDate;

    if (baseDate.day >= monthSettings.startDay) {
      // We're after the start day in the current month
      startDate =
          DateTime(baseDate.year, baseDate.month, monthSettings.startDay);
      endDate = DateTime(
          baseDate.year, baseDate.month + 1, monthSettings.startDay - 1);
    } else {
      // We're before the start day, so we're in the previous month's cycle
      startDate =
          DateTime(baseDate.year, baseDate.month - 1, monthSettings.startDay);
      endDate =
          DateTime(baseDate.year, baseDate.month, monthSettings.startDay - 1);
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  // New method to get today's expenses
  Future<double> _getTodaysExpenses() async {
    try {
      // Get today's date at midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Get all transactions for today
      final transactions = await DatabaseHelper.instance
          .getTransactionsForPeriod(
              today, tomorrow.subtract(const Duration(seconds: 1)));

      // Sum up all expenses for today
      double totalExpenses = 0;
      for (var transaction in transactions) {
        if (!transaction.isIncome) {
          totalExpenses += transaction.amount;
        }
      }

      return totalExpenses;
    } catch (e) {
      debugPrint('Error calculating today\'s expenses: $e');
      return 0;
    }
  }

  Future<void> _loadData() async {
    try {
      // Get date range for the specified month offset
      final dateRange = await _getDateRangeForOffset(widget.monthOffset);
      final startDate = dateRange['startDate'];
      final endDate = dateRange['endDate'];

      // If we're showing the current month, use the regular service methods
      if (widget.monthOffset == 0) {
        // Use the new method to get today's expenses instead of last purchase
        final todaysExpenses = await _getTodaysExpenses();

        // Use the new Daily Purchase Rate service instead of daily spending rate
        final dailyPurchaseRate = await DailyPurchaseRateService.instance
            .getDailyPurchaseRate(forceRefresh: true);

        // Get current month's spent and budget goal to calculate coverage percentage
        final spent = await BudgetDataService.instance
            .getCurrentMonthSpent(forceRefresh: true);
        final budgetGoal = await BudgetDataService.instance
            .getMonthlyBudgetGoal(forceRefresh: true);

        // Calculate coverage percentage (spent as percentage of budget goal)
        final coverage = (spent / budgetGoal) * 100;

        if (mounted) {
          setState(() {
            _todaysExpense = todaysExpenses;
            _dailyPurchaseRate = dailyPurchaseRate;
            _budgetCoverage = coverage.clamp(0, 100); // Clamp between 0-100%
            _isLoading = false;
          });
        }
      } else {
        // For historical months, we need to calculate these values ourselves
        // Get transactions for this period
        final transactions = await DatabaseHelper.instance
            .getTransactionsForPeriod(startDate, endDate);

        // Filter for expense transactions
        final expenses = transactions.where((t) => !t.isIncome).toList();

        // For historical months, show the total expenses (not today's)
        double totalExpenses = 0;
        for (var expense in expenses) {
          totalExpenses += expense.amount;
        }

        // Get month-specific budget goal for this historical month
        final monthDate = DateTime(
            DateTime.now().year, DateTime.now().month + widget.monthOffset, 1);

        final budgetGoal = await BudgetDataService.instance
            .getMonthlyBudgetGoal(forceRefresh: true, forMonth: monthDate);

        // Calculate coverage
        final coverage = (totalExpenses / budgetGoal) * 100;

        if (mounted) {
          setState(() {
            // For historical months, show monthly total instead of today's expenses
            _todaysExpense = totalExpenses;
            _dailyPurchaseRate = 0; // TBD for historical months
            _budgetCoverage = coverage.clamp(0, 100);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading monthly stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Return the MonthlyStats widget with the today's expense instead of last purchase
    return MonthlyStats(
      todaysExpense: _todaysExpense,
      dailyPurchaseRate: _dailyPurchaseRate,
      budgetCoverage: _budgetCoverage,
      showTBD: widget.monthOffset != 0, // Show TBD for historical months
    );
  }
}
