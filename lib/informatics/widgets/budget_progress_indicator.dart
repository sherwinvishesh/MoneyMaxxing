// lib/informatics/widgets/budget_progress_indicator.dart
import 'package:flutter/material.dart';
import 'package:moneymaxxing/services/currency_service.dart';
import '../services/budget_data_service.dart';
import '../../services/database_helper.dart';
import 'package:intl/intl.dart';

class BudgetProgressIndicator extends StatefulWidget {
  final VoidCallback? onRefreshCompleted;

  const BudgetProgressIndicator({
    super.key,
    this.onRefreshCompleted,
  });

  @override
  BudgetProgressIndicatorState createState() => BudgetProgressIndicatorState();
}

class BudgetProgressIndicatorState extends State<BudgetProgressIndicator> {
  double _currentIncome = 0;
  double _incomeGoal = 1; // Default to 1 to avoid division by zero
  double _currentExpense = 0;
  double _budgetGoal = 1; // Budget line
  bool _isLoading = true;
  String _dateRange = '';

  // Track the current month offset (0 = current month, -1 = previous month, etc.)
  int _currentMonthOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      double expense = 0;
      for (var transaction in transactions) {
        if (transaction.isIncome) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      // Get income goal and budget goal from settings
      final settings = await DatabaseHelper.instance.getBudgetSettings();
      final incomeGoal = settings.totalIncomeGoal;
      final budgetGoal = settings.totalBudgetGoal;

      if (mounted) {
        setState(() {
          _currentIncome = income;
          _incomeGoal =
              incomeGoal > 0 ? incomeGoal : 1; // Avoid division by zero
          _currentExpense = expense;
          _budgetGoal =
              budgetGoal > 0 ? budgetGoal : 1; // Avoid division by zero
          _dateRange = dateRange['formattedRange'];
          _isLoading = false;
        });

        // Notify parent when refresh is completed if callback is provided
        if (widget.onRefreshCompleted != null) {
          widget.onRefreshCompleted!();
        }
      }
    } catch (e) {
      debugPrint('Error loading budget progress data: $e');
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
        height: 150,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate percentages for display
    final incomePercentage = (_currentIncome / _incomeGoal).clamp(0.0, 1.0);
    final budgetPercentage = (_budgetGoal / _incomeGoal).clamp(0.0, 1.0);
    final expensePercentage = (_currentExpense / _incomeGoal).clamp(0.0, 1.0);

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
                  'Budget Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Month navigation controls
                Row(
                  children: [
                    // Previous month button
                    IconButton(
                      onPressed: _navigateToPreviousMonth,
                      icon: const Icon(Icons.chevron_left, color: Colors.blue),
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                    // Date range display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            _dateRange,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Next month button (disabled when at current month)
                    IconButton(
                      onPressed:
                          _currentMonthOffset < 0 ? _navigateToNextMonth : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: _currentMonthOffset < 0
                            ? Colors.blue
                            : Colors.grey.withOpacity(0.5),
                      ),
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Indicator arrows for current income and expense positions
            SizedBox(
              width: double.infinity,
              height: 16,
              child: LayoutBuilder(builder: (context, constraints) {
                // Calculate exact positions based on the actual progress bar width
                final progressBarWidth = constraints.maxWidth;
                final incomeIndicatorPos =
                    (progressBarWidth * incomePercentage) - 6;
                final expenseIndicatorPos =
                    (progressBarWidth * expensePercentage) - 6;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Income position arrow (green)
                    Positioned(
                      left: incomeIndicatorPos,
                      child: _buildTriangleIndicator(
                          const Color(0xFF7BC043)), // Bright green
                    ),

                    // Expense position arrow (red)
                    Positioned(
                      left: expenseIndicatorPos,
                      child: _buildTriangleIndicator(
                          const Color(0xFFFF5252)), // Bright red
                    ),
                  ],
                );
              }),
            ),

            // Custom Budget Progress Bar
            Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Income progress (green)
                  FractionallySizedBox(
                    widthFactor: incomePercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFF7BC043), // Brighter green that matches screenshot
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Expense progress (red) - Always on top of green
                  FractionallySizedBox(
                    widthFactor: expensePercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFFF5252), // Pure red color instead of semi-transparent
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Budget line indicator
                  Positioned(
                    left: MediaQuery.of(context).size.width *
                        budgetPercentage *
                        0.9, // Adjust for padding
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Legend and values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Income info
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFF7BC043), // Matching the progress bar green
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FutureBuilder<String>(
                      future: CurrencyService.instance.getCurrencySymbol(),
                      builder: (context, snapshot) {
                        final symbol = snapshot.data ?? '\$';
                        return Text(
                          'Income: $symbol${_currentIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Budget line info
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    FutureBuilder<String>(
                      future: CurrencyService.instance.getCurrencySymbol(),
                      builder: (context, snapshot) {
                        final symbol = snapshot.data ?? '\$';
                        return Text(
                          'Budget Line: $symbol${_budgetGoal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Expense info
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFFF5252), // Matching the progress bar red
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FutureBuilder<String>(
                      future: CurrencyService.instance.getCurrencySymbol(),
                      builder: (context, snapshot) {
                        final symbol = snapshot.data ?? '\$';
                        return Text(
                          'Expense: $symbol${_currentExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Helper method to build triangle indicators
  Widget _buildTriangleIndicator(Color color) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: TriangleIndicatorPainter(color: color),
    );
  }
}

// Custom painter to draw triangle indicators - pointing DOWN toward the bar
class TriangleIndicatorPainter extends CustomPainter {
  final Color color;

  TriangleIndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a downward-pointing triangle
    final Path path = Path()
      ..moveTo(size.width / 2, size.height) // Bottom center point
      ..lineTo(0, 0) // Top left point
      ..lineTo(size.width, 0) // Top right point
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
