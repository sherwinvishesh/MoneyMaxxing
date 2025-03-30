// lib/informatics/widgets/monthly_category_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';
import '../../services/currency_service.dart';
import '../../models/financial_transaction.dart';
import 'dart:math' as math;

class MonthlyCategoryChart extends StatefulWidget {
  const MonthlyCategoryChart({
    super.key,
    this.onRefreshCompleted,
  });

  final VoidCallback? onRefreshCompleted;

  @override
  MonthlyCategoryChartState createState() => MonthlyCategoryChartState();
}

class MonthlyCategoryChartState extends State<MonthlyCategoryChart> {
  bool _isLoading = true;
  Map<String, double> _categorySpending = {};
  Map<String, Color> _categoryColors = {};
  double _totalSpending = 0;
  String _dateRange = '';

  // Track the current month offset (0 = current month, -1 = previous month, etc.)
  int _currentMonthOffset = 0;

  // Track the currently touched section for displaying info
  int? _touchedIndex;

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

      // Set date range from the returned formatted range
      _dateRange = dateRange['formattedRange'];

      // Load transactions for this period
      final transactions = await DatabaseHelper.instance
          .getTransactionsForPeriod(startDate, endDate);

      // Load all categories to get their colors
      final categories = await DatabaseHelper.instance.getAllCategories();
      _categoryColors = {};
      for (final category in categories) {
        _categoryColors[category.name] = category.color;
      }

      // Calculate spending by category
      _categorySpending = {};
      _totalSpending = 0;

      for (var transaction in transactions) {
        // Skip income transactions
        if (transaction.isIncome) continue;

        // If transaction has a category, add to that category's total
        if (transaction.category != null) {
          _categorySpending[transaction.category!] =
              (_categorySpending[transaction.category!] ?? 0) +
                  transaction.amount;
          _totalSpending += transaction.amount;
        }
      }

      // Sort categories by spending amount (descending)
      _categorySpending = Map.fromEntries(_categorySpending.entries.toList()
        ..sort((e1, e2) => e2.value.compareTo(e1.value)));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _touchedIndex = null; // Reset touched index when data changes
        });

        if (widget.onRefreshCompleted != null) {
          widget.onRefreshCompleted!();
        }
      }
    } catch (e) {
      debugPrint('Error loading category spending data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF212121),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Spending by Category',
                  style: TextStyle(
                    fontSize: 14,
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

            const SizedBox(height: 30), // Increased top spacing

            // Chart container with fixed height and proper padding
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 350, // Fixed height for the chart container
              padding: const EdgeInsets.symmetric(vertical: 20), // Add padding
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categorySpending.isEmpty
                      ? const Center(
                          child: Text(
                            'No expenses for this period',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Sized chart container
                            Expanded(
                              child: Stack(
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sections: _buildPieSections(),
                                      centerSpaceRadius:
                                          100, // Smaller center hole for more compact chart
                                      sectionsSpace: 3,
                                      borderData: FlBorderData(show: false),
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event,
                                            pieTouchResponse) {
                                          setState(() {
                                            if (pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
                                                    null ||
                                                !event
                                                    .isInterestedForInteractions) {
                                              _touchedIndex = -1;
                                              return;
                                            }
                                            _touchedIndex = pieTouchResponse
                                                .touchedSection!
                                                .touchedSectionIndex;
                                          });
                                        },
                                        enabled: true,
                                      ),
                                    ),
                                    swapAnimationDuration:
                                        const Duration(milliseconds: 150),
                                  ),
                                  // Center overlay
                                  Center(
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF212121),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  // Show selected category info in center when a section is touched
                                  if (_touchedIndex != null &&
                                      _touchedIndex! >= 0 &&
                                      _touchedIndex! <
                                          _categorySpending.entries.length)
                                    Center(
                                      child: _buildTouchedCategoryInfo(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),

            const SizedBox(
                height: 30), // Increased bottom spacing before legend

            // Category legend
            if (!_isLoading && _categorySpending.isNotEmpty)
              _buildCategoryLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchedCategoryInfo() {
    final entries = _categorySpending.entries.toList();
    if (_touchedIndex! >= entries.length) return const SizedBox();

    final entry = entries[_touchedIndex!];
    final category = entry.key;
    final amount = entry.value;
    final percentage = (amount / _totalSpending) * 100;
    final color = _categoryColors[category] ?? Colors.blue;

    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          FutureBuilder<String>(
            future: CurrencyService.instance.getCurrencySymbol(),
            builder: (context, snapshot) {
              final symbol = snapshot.data ?? '\$';
              return Text(
                '$symbol${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final sections = <PieChartSectionData>[];

    // Convert map to list for indexing
    final List<MapEntry<String, double>> categoryEntries =
        _categorySpending.entries.toList();

    for (int i = 0; i < categoryEntries.length; i++) {
      final entry = categoryEntries[i];
      final String category = entry.key;
      final double amount = entry.value;

      // Calculate percentage
      final percentage = (amount / _totalSpending) * 100;

      // Get category color or use a default if not found
      final color = _categoryColors[category] ?? Colors.blue;

      // Check if this section is being touched/hovered
      final isTouched = i == _touchedIndex;

      // Enlarge the section slightly when touched
      final double radius = isTouched ? 70 : 60;

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '', // Never show title inside the chart
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black,
                offset: Offset(0, 1),
              ),
            ],
          ),
          showTitle: false,
          // No badge widget - we'll show info in the center instead
          badgeWidget: null,
          badgePositionPercentageOffset: 0,
        ),
      );
    }

    return sections;
  }

  Widget _buildCategoryLegend() {
    return FutureBuilder<String>(
      future: CurrencyService.instance.getCurrencySymbol(),
      builder: (context, snapshot) {
        final symbol = snapshot.data ?? '\$';

        // Create a list of widgets for each category
        final List<Widget> categoryItems = [];

        _categorySpending.forEach((category, amount) {
          final color = _categoryColors[category] ?? Colors.blue;

          categoryItems.add(
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$symbol${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });

        // Display items in a row with wrap - using better padding
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 24.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.spaceAround,
            children: categoryItems,
          ),
        );
      },
    );
  }
}
