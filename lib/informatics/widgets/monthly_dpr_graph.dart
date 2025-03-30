// lib/informatics/widgets/monthly_dpr_graph.dart
// to be updated in the future, aka "FUTURE REFERENCE"
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/currency_service.dart';

class MonthlyDPRGraph extends StatefulWidget {
  const MonthlyDPRGraph({
    super.key,
    this.onRefreshCompleted,
  });

  final VoidCallback? onRefreshCompleted;

  @override
  MonthlyDPRGraphState createState() => MonthlyDPRGraphState();
}

class MonthlyDPRGraphState extends State<MonthlyDPRGraph> {
  bool _isLoading = false;
  String _dateRange = 'Feb 1 - Feb 29';
  int _currentMonthOffset = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      // Simulate loading
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isLoading = false;
      });

      if (widget.onRefreshCompleted != null) {
        widget.onRefreshCompleted!();
      }
    }
  }

  // Navigate to previous month
  void _navigateToPreviousMonth() {
    if (mounted) {
      setState(() {
        _currentMonthOffset -= 1;
        _dateRange = 'XXX 1 - XXX 30';
      });
    }
  }

  // Navigate to next month
  void _navigateToNextMonth() {
    if (_currentMonthOffset < 0) {
      if (mounted) {
        setState(() {
          _currentMonthOffset += 1;
          _dateRange = 'XXX 1 - XXX 30';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly DPR Graph',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                      child: Center(
                        child: Text(
                          'Placeholder for DPR Graph',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(
            'Recurring Expenses',
            'XXX.XX',
            Colors.grey,
          ),
          const SizedBox(width: 24),
          _legendItem(
            'DPR Projection',
            'XXX.XX/day',
            Colors.red,
            isDotted: true,
            showPerDay: true,
          ),
          const SizedBox(width: 24),
          _legendItem(
            'DPR',
            'XXX.XX/day',
            Colors.yellow,
            showPerDay: true,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, String value, Color color,
      {bool isDotted = false, bool showPerDay = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDotted
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        (width ~/ 4).clamp(2, 10),
                        (index) => Container(
                          width: 2,
                          height: 3,
                          color: color,
                        ),
                      ),
                    );
                  },
                )
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
