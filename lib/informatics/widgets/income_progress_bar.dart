// Modified lib/informatics/widgets/income_progress_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymaxxing/services/currency_service.dart';
import '../services/budget_data_service.dart';
import '../../services/database_helper.dart';

class IncomeProgressBar extends StatefulWidget {
  final VoidCallback? onRefreshCompleted;

  const IncomeProgressBar({
    super.key,
    this.onRefreshCompleted,
  });

  @override
  IncomeProgressBarState createState() => IncomeProgressBarState();
}

class IncomeProgressBarState extends State<IncomeProgressBar> {
  double _currentIncome = 0;
  double _incomeGoal = 1; // Default to 1 to avoid division by zero
  bool _isLoading = true;
  String _dateRange = '';

  // Track the current month offset (0 = current month, -1 = previous month, etc.)
  int _currentMonthOffset = 0;

  // Add a placeholder for currency symbol to avoid layout shifts
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol(); // Pre-load currency symbol
    _loadData();
  }

  // Pre-load currency symbol to avoid layout shifts
  Future<void> _loadCurrencySymbol() async {
    try {
      final symbol = await CurrencyService.instance.getCurrencySymbol();
      if (mounted) {
        setState(() {
          _currencySymbol = symbol;
        });
      }
    } catch (e) {
      // Keep default if there's an error
    }
  }

  // Navigate to previous month
  void _navigateToPreviousMonth() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _currentMonthOffset -= 1;
      });
    }
    _loadData();
  }

  // Navigate to next month
  void _navigateToNextMonth() {
    // Don't allow navigating to future months
    if (_currentMonthOffset < 0) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _currentMonthOffset += 1;
        });
      }
      _loadData();
    }
  }

  Future<void> refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    await _loadData();
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

    // Format the date range
    final dateFormatter = DateFormat('MMM d');
    final range =
        '${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}';

    return {
      'startDate': startDate,
      'endDate': endDate,
      'formattedRange': range,
    };
  }

  Future<void> _loadData() async {
    try {
      // Get date range for the current offset
      final dateRange = await _getDateRangeForOffset(_currentMonthOffset);
      final startDate = dateRange['startDate'];
      final endDate = dateRange['endDate'];

      // Load transactions for this period
      final transactions = await DatabaseHelper.instance
          .getTransactionsForPeriod(startDate, endDate);

      // Calculate total income for this period
      double income = 0;
      for (var transaction in transactions) {
        if (transaction.isIncome) {
          income += transaction.amount;
        }
      }

      // Get income goal from settings
      final settings = await DatabaseHelper.instance.getBudgetSettings();
      final incomeGoal = settings.totalIncomeGoal;

      if (mounted) {
        setState(() {
          _currentIncome = income;
          _incomeGoal =
              incomeGoal > 0 ? incomeGoal : 1; // Avoid division by zero
          _dateRange = dateRange['formattedRange'];
          _isLoading = false;
        });

        // Notify parent when refresh is completed if callback is provided
        if (widget.onRefreshCompleted != null) {
          widget.onRefreshCompleted!();
        }
      }
    } catch (e) {
      debugPrint('Error loading income data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage - always use valid data even during loading
    final percentage = (_currentIncome / _incomeGoal).clamp(0.0, 1.0);

    return Card(
      color: const Color(0xFF212121),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Income Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Month navigation controls with Expanded layout
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Previous month button
                      IconButton(
                        onPressed: _isLoading ? null : _navigateToPreviousMonth,
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.green),
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),

                      // Date range display - FittedBox to prevent overflow
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  _isLoading ? "Loading..." : _dateRange,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Next month button (disabled when at current month)
                      IconButton(
                        onPressed: _isLoading || _currentMonthOffset >= 0
                            ? null
                            : _navigateToNextMonth,
                        icon: Icon(
                          Icons.chevron_right,
                          color: _currentMonthOffset < 0 && !_isLoading
                              ? Colors.green
                              : Colors.grey.withOpacity(0.5),
                        ),
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Always show the progress indicator, even during loading
            // This prevents layout shifts during data loading
            Stack(
              children: [
                // Background progress bar
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.green.withOpacity(0.2),
                  color: Colors.green,
                  minHeight: 16,
                  borderRadius: BorderRadius.circular(8),
                ),

                // Loading indicator overlay (only shown when loading)
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Use cached currency symbol to prevent layout shifts
                Text(
                  '$_currencySymbol${_currentIncome.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Goal: $_currencySymbol${_incomeGoal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}% of income goal reached',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
