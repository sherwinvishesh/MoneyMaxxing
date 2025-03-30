// lib/informatics/widgets/weekly_expenditure_graph.dart
import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/currency_service.dart'; // Add import for CurrencyService
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeeklyExpenditureGraph extends StatefulWidget {
  const WeeklyExpenditureGraph({
    super.key,
    this.onRefreshCompleted,
  });

  final VoidCallback? onRefreshCompleted;

  @override
  WeeklyExpenditureGraphState createState() => WeeklyExpenditureGraphState();
}

class WeeklyExpenditureGraphState extends State<WeeklyExpenditureGraph> {
  bool _isLoading = true;
  List<FlSpot> _dailyExpenseSpots = [];
  double _maxExpense = 100; // Default maximum value
  int _weekOffset = 0; // 0 = current week, -1 = last week, etc.
  String _dateRange = '';
  List<String> _weekDays = [];
  Map<int, double> _dailyExpenses = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
      await _loadData();
    }
  }

  // Navigate to previous week
  void _navigateToPreviousWeek() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _weekOffset -= 1;
      });
    }
    _loadData();
  }

  // Navigate to next week
  void _navigateToNextWeek() {
    // Don't allow navigating to future weeks
    if (_weekOffset < 0) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _weekOffset += 1;
        });
      }
      _loadData();
    }
  }

  // Get start and end dates for a week based on the offset
  Map<String, DateTime> _getWeekDates(int weekOffset) {
    // Get today's date
    final now = DateTime.now();

    // Find the most recent Monday (beginning of the week)
    final today = DateTime(now.year, now.month, now.day);
    int daysToSubtract = (today.weekday - 1) % 7; // Monday is 1, Sunday is 7

    // Calculate the Monday of the current week
    final thisMonday = today.subtract(Duration(days: daysToSubtract));

    // Apply the week offset
    final targetMonday = thisMonday.add(Duration(days: 7 * weekOffset));
    final targetSunday = targetMonday.add(const Duration(days: 6));

    return {
      'startDate': targetMonday,
      'endDate': targetSunday,
    };
  }

  Future<void> _loadData() async {
    try {
      // Get the week's date range
      final weekDates = _getWeekDates(_weekOffset);
      final startDate = weekDates['startDate']!;
      final endDate = weekDates['endDate']!;

      // Format the date range for display
      final dateFormatter = DateFormat('MMM d');
      _dateRange =
          '${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}';

      // Prepare day names and initialize expenses to 0
      _weekDays = [];
      _dailyExpenses = {};

      // Initialize data for each day of the week
      for (int i = 0; i < 7; i++) {
        final day = startDate.add(Duration(days: i));

        // Get short day name (Mon, Tue, etc.)
        final dayName = DateFormat('E').format(day);
        _weekDays.add(dayName);

        // Initialize expenses for this day to 0
        _dailyExpenses[i] = 0;
      }

      // Get transactions for the week
      final transactions = await DatabaseHelper.instance
          .getTransactionsForPeriod(
              startDate,
              endDate
                  .add(const Duration(days: 1))
                  .subtract(const Duration(seconds: 1)));

      // Calculate total expenses for each day
      for (final transaction in transactions) {
        if (!transaction.isIncome) {
          // Calculate day index (0 = Monday, 6 = Sunday)
          final transactionDate = transaction.dateTime;
          final daysDifference = transactionDate.difference(startDate).inDays;

          // Only count transactions within our week range
          if (daysDifference >= 0 && daysDifference < 7) {
            _dailyExpenses[daysDifference] =
                (_dailyExpenses[daysDifference] ?? 0) + transaction.amount;
          }
        }
      }

      // Convert daily expenses to chart spots
      _dailyExpenseSpots = [];
      double maxValue = 0;

      for (int i = 0; i < 7; i++) {
        final expense = _dailyExpenses[i] ?? 0;
        _dailyExpenseSpots.add(FlSpot(i.toDouble(), expense));

        // Track maximum expense for scaling
        if (expense > maxValue) {
          maxValue = expense;
        }
      }

      // Ensure we have a reasonable max value for the chart
      _maxExpense = maxValue > 0 ? (maxValue * 1.2) : 100;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (widget.onRefreshCompleted != null) {
          widget.onRefreshCompleted!();
        }
      }
    } catch (e) {
      debugPrint('Error loading weekly expenditure data: $e');
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
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                  'Weekly Expenditure',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Week navigation controls
                Row(
                  children: [
                    // Previous week button
                    IconButton(
                      onPressed: _navigateToPreviousWeek,
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
                    // Next week button (disabled when at current week)
                    IconButton(
                      onPressed: _weekOffset < 0 ? _navigateToNextWeek : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: _weekOffset < 0
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

            // Weekly expenditure bar chart
            SizedBox(
              height: 250,
              child: FutureBuilder<String>(
                  future: CurrencyService.instance.getCurrencySymbol(),
                  builder: (context, currencySnapshot) {
                    final currencySymbol = currencySnapshot.data ?? '\$';

                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _maxExpense,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: const Color(0xFF303030),
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final amount = _dailyExpenses[groupIndex] ?? 0;
                              return BarTooltipItem(
                                '$currencySymbol${amount.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Show day name (Mon, Tue, etc.)
                                final index = value.toInt();
                                if (index >= 0 && index < _weekDays.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _weekDays[index],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _maxExpense / 5,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) {
                                  return Text(
                                    '$currencySymbol${0}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  );
                                }
                                if (value > 0 && value <= _maxExpense) {
                                  return Text(
                                    '$currencySymbol${value.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: List.generate(
                          7,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _dailyExpenses[index] ?? 0,
                                color: Colors.blue,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _maxExpense / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: const Color(0xFF404040),
                              strokeWidth: 1,
                            );
                          },
                        ),
                      ),
                    );
                  }),
            ),

            const SizedBox(height: 16),

            // Total expenditure for the week
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FutureBuilder<String>(
                    future: CurrencyService.instance.getCurrencySymbol(),
                    builder: (context, snapshot) {
                      final symbol = snapshot.data ?? '\$';
                      final totalExpenditure = _dailyExpenses.values
                          .fold(0.0, (sum, value) => sum + value);

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Weekly Expenditure',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$symbol${totalExpenditure.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
