// lib/screens/budget_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/budget_settings.dart';
import '../services/database_helper.dart';
import 'dashboard_screen.dart';
import '../services/currency_service.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeGoalController = TextEditingController();
  final _savingsGoalController = TextEditingController();
  final _budgetGoalController = TextEditingController();

  bool _isLoading = true;
  bool _isIncomeGoalChanging = false;
  bool _isSavingsGoalChanging = false;
  bool _isBudgetGoalChanging = false;
  bool _applyToFuture = true; // Default to applying changes to future months

  // Store original values to revert if needed
  double _originalIncomeGoal = 0.0;
  double _originalSavingsGoal = 0.0;
  double _originalBudgetGoal = 0.0;

  // Month navigation state
  DateTime _selectedMonth = DateTime.now();
  String _monthYearKey = ''; // Format: YYYY-MM
  String _formattedMonthYear = ''; // For display only

  @override
  void initState() {
    super.initState();
    _initializeSelectedMonth();
    _loadBudgetSettings();
  }

  void _initializeSelectedMonth() {
    // Set monthYearKey to current month in YYYY-MM format
    _selectedMonth = DateTime.now();
    _monthYearKey =
        "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
    _formattedMonthYear = DateFormat('MMMM yyyy').format(_selectedMonth);
  }

  Future<void> _loadBudgetSettings() async {
    try {
      final settings = await DatabaseHelper.instance
          .getBudgetSettings(monthYear: _monthYearKey);

      if (mounted) {
        setState(() {
          _originalIncomeGoal = settings.totalIncomeGoal;
          _originalSavingsGoal = settings.totalSavingsGoal;
          _originalBudgetGoal = settings.totalBudgetGoal;

          _incomeGoalController.text =
              settings.totalIncomeGoal.toStringAsFixed(2);
          _savingsGoalController.text =
              settings.totalSavingsGoal.toStringAsFixed(2);
          _budgetGoalController.text =
              settings.totalBudgetGoal.toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading budget settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetToOriginalValues() {
    setState(() {
      _incomeGoalController.text = _originalIncomeGoal.toStringAsFixed(2);
      _savingsGoalController.text = _originalSavingsGoal.toStringAsFixed(2);
      _budgetGoalController.text = _originalBudgetGoal.toStringAsFixed(2);
    });
  }

  void _navigateToPreviousMonth() {
    setState(() {
      _isLoading = true;
      // Go to previous month
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      _monthYearKey =
          "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
      _formattedMonthYear = DateFormat('MMMM yyyy').format(_selectedMonth);
    });
    _loadBudgetSettings();
  }

  void _navigateToNextMonth() {
    final now = DateTime.now();
    // Don't allow navigating more than 12 months into the future
    if (_selectedMonth.year * 12 + _selectedMonth.month <
        now.year * 12 + now.month + 12) {
      setState(() {
        _isLoading = true;
        // Go to next month
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
        _monthYearKey =
            "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
        _formattedMonthYear = DateFormat('MMMM yyyy').format(_selectedMonth);
      });
      _loadBudgetSettings();
    }
  }

  bool _isCurrentOrFutureMonth() {
    final now = DateTime.now();
    return (_selectedMonth.year > now.year) ||
        (_selectedMonth.year == now.year && _selectedMonth.month >= now.month);
  }

  Future<void> _saveBudgetSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Validate values before saving
      final incomeGoal = double.tryParse(_incomeGoalController.text) ?? 0.0;
      final savingsGoal = double.tryParse(_savingsGoalController.text) ?? 0.0;
      final budgetGoal = double.tryParse(_budgetGoalController.text) ?? 0.0;

      if (incomeGoal <= 0) {
        _showErrorDialog("Income goal must be greater than zero.");
        _resetToOriginalValues();
        return;
      }

      if (savingsGoal < 0 || budgetGoal < 0) {
        _showErrorDialog("Savings goal and budget goal cannot be negative.");
        _resetToOriginalValues();
        return;
      }

      if ((savingsGoal + budgetGoal) != incomeGoal) {
        _showErrorDialog(
            "The sum of savings goal and budget goal must equal income goal.");
        _resetToOriginalValues();
        return;
      }

      final settings = BudgetSettings(
        totalIncomeGoal: incomeGoal,
        totalSavingsGoal: savingsGoal,
        monthYear: _monthYearKey,
      );

      // Only apply to future months if:
      // 1. The checkbox is checked AND
      // 2. We are modifying current or future month
      final shouldApplyToFuture = _applyToFuture && _isCurrentOrFutureMonth();

      await DatabaseHelper.instance
          .saveBudgetSettings(settings, applyToFuture: shouldApplyToFuture);

      // Update original values after successful save
      _originalIncomeGoal = incomeGoal;
      _originalSavingsGoal = savingsGoal;
      _originalBudgetGoal = budgetGoal;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldApplyToFuture
                ? 'Budget settings saved and applied to future months'
                : 'Budget settings saved for $_formattedMonthYear'),
          ),
        );

        // Get reference to navigator before popping
        final navigator = Navigator.of(context);
        navigator.pop();

        // Try to refresh the dashboard after returning
        try {
          // This will run after the pop operation completes
          Future.delayed(const Duration(milliseconds: 100), () {
            // Find the dashboard screen state and refresh it
            final dashboardState = navigator.context
                .findAncestorStateOfType<DashboardScreenState>();
            dashboardState?.refreshExpenditures();
          });
        } catch (e) {
          debugPrint('Error setting up dashboard refresh: $e');
        }
      }
    } catch (e) {
      print('Error saving budget settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving budget settings')),
        );
        _resetToOriginalValues();
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onIncomeGoalChanged(String value) {
    _isIncomeGoalChanging = true;

    if (value.isEmpty) {
      _isIncomeGoalChanging = false;
      return;
    }

    final incomeGoal = double.tryParse(value);
    if (incomeGoal == null || incomeGoal <= 0) {
      _isIncomeGoalChanging = false;
      return;
    }

    try {
      final budgetGoal = double.tryParse(_budgetGoalController.text) ?? 0.0;
      final newSavingsGoal = incomeGoal - budgetGoal;

      if (newSavingsGoal >= 0) {
        _savingsGoalController.text = newSavingsGoal.toStringAsFixed(2);
      } else {
        // If income goal is too low to maintain budget goal, adjust both values
        final adjustedSavingsGoal = incomeGoal * 0.2; // 20% goes to savings
        _savingsGoalController.text = adjustedSavingsGoal.toStringAsFixed(2);
        _budgetGoalController.text =
            (incomeGoal - adjustedSavingsGoal).toStringAsFixed(2);
      }

      setState(() {});
    } catch (e) {
      print('Error updating values: $e');
      _resetToOriginalValues();
    }

    _isIncomeGoalChanging = false;
  }

  void _onSavingsGoalChanged(String value) {
    if (_isIncomeGoalChanging || _isBudgetGoalChanging) return;

    _isSavingsGoalChanging = true;

    if (value.isEmpty) {
      _isSavingsGoalChanging = false;
      return;
    }

    try {
      final incomeGoal = double.tryParse(_incomeGoalController.text) ?? 0.0;
      double savingsGoal = double.tryParse(value) ?? 0.0;

      // Ensure savings goal is not negative and not greater than income goal
      if (savingsGoal < 0) {
        savingsGoal = 0.0;
        _savingsGoalController.text = savingsGoal.toStringAsFixed(2);
      } else if (savingsGoal > incomeGoal) {
        savingsGoal = incomeGoal;
        _savingsGoalController.text = savingsGoal.toStringAsFixed(2);
      }

      // When savings goal changes, update budget goal
      final newBudgetGoal = incomeGoal - savingsGoal;
      _budgetGoalController.text = newBudgetGoal.toStringAsFixed(2);

      // Update UI state for slider
      setState(() {});
    } catch (e) {
      print('Error updating values: $e');
      _resetToOriginalValues();
    }

    _isSavingsGoalChanging = false;
  }

  void _onBudgetGoalChanged(String value) {
    if (_isIncomeGoalChanging || _isSavingsGoalChanging) return;

    _isBudgetGoalChanging = true;

    if (value.isEmpty) {
      _isBudgetGoalChanging = false;
      return;
    }

    try {
      final incomeGoal = double.tryParse(_incomeGoalController.text) ?? 0.0;
      double budgetGoal = double.tryParse(value) ?? 0.0;

      // Ensure budget goal is not negative and not greater than income goal
      if (budgetGoal < 0) {
        budgetGoal = 0.0;
        _budgetGoalController.text = budgetGoal.toStringAsFixed(2);
      } else if (budgetGoal > incomeGoal) {
        budgetGoal = incomeGoal;
        _budgetGoalController.text = budgetGoal.toStringAsFixed(2);
      }

      // When budget goal changes, update savings goal
      final newSavingsGoal = incomeGoal - budgetGoal;
      _savingsGoalController.text = newSavingsGoal.toStringAsFixed(2);

      // Update UI state for slider
      setState(() {});
    } catch (e) {
      print('Error updating values: $e');
      _resetToOriginalValues();
    }

    _isBudgetGoalChanging = false;
  }

  double _getBudgetGoalPercentage() {
    final incomeGoal = double.tryParse(_incomeGoalController.text) ?? 0.0;
    final budgetGoal = double.tryParse(_budgetGoalController.text) ?? 0.0;

    if (incomeGoal <= 0) return 0;

    // Use budget goal/income goal ratio instead of savings/income
    final percentage = budgetGoal / incomeGoal;
    return percentage.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Budget Settings'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month Selection Controls
                    Card(
                      color: const Color(0xFF212121),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous month button
                            IconButton(
                              onPressed: _navigateToPreviousMonth,
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.blue),
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
                                    _formattedMonthYear,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Next month button
                            IconButton(
                              onPressed: _navigateToNextMonth,
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.blue),
                              iconSize: 28,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFF212121),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'Total Income Goal',
                              controller: _incomeGoalController,
                              onChanged: _onIncomeGoalChanged,
                            ),
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.remove,
                              color: Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              label: 'Total Budget Goal',
                              controller: _budgetGoalController,
                              onChanged: _onBudgetGoalChanged,
                            ),
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              label: 'Total Savings Goal',
                              controller: _savingsGoalController,
                              onChanged: _onSavingsGoalChanged,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      color: const Color(0xFF212121),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Adjust Balance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Budget Goal',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                const Text(
                                  'Savings Goal',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 10,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 20),
                                // Swap these colors
                                activeTrackColor: Colors.blue, // Was blue
                                inactiveTrackColor: Colors.green, // Was green
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                // Use budget goal percentage instead of savings percentage
                                value: _getBudgetGoalPercentage(),
                                onChanged: (value) {
                                  final incomeGoal = double.tryParse(
                                          _incomeGoalController.text) ??
                                      0.0;
                                  if (incomeGoal <= 0) return;

                                  // Calculate new budget goal based on percentage (rounded to $5)
                                  double newBudgetGoal = incomeGoal * value;
                                  newBudgetGoal =
                                      (newBudgetGoal / 5).round() * 5;
                                  if (newBudgetGoal > incomeGoal)
                                    newBudgetGoal = incomeGoal;

                                  // Update controllers
                                  _budgetGoalController.text =
                                      newBudgetGoal.toStringAsFixed(2);
                                  _savingsGoalController.text =
                                      (incomeGoal - newBudgetGoal)
                                          .toStringAsFixed(2);
                                  setState(() {});
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${_budgetGoalController.text}',
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${_savingsGoalController.text}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Apply to future months option - only show for current or future months
                    if (_isCurrentOrFutureMonth())
                      Card(
                        color: const Color(0xFF212121),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Apply to future months',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _applyToFuture,
                                onChanged: (value) {
                                  setState(() {
                                    _applyToFuture = value;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveBudgetSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(
                        _isCurrentOrFutureMonth() && _applyToFuture
                            ? 'Save Budget Settings & Apply to Future'
                            : 'Save Budget Settings for $_formattedMonthYear',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return FutureBuilder<String>(
        future: CurrencyService.instance.getCurrencySymbol(),
        builder: (context, snapshot) {
          final currencySymbol =
              snapshot.data ?? '\$'; // Default to $ if not loaded yet

          return TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.grey),
              prefixText: '$currencySymbol ',
              prefixStyle: const TextStyle(color: Colors.white),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: onChanged,
          );
        });
  }

  @override
  void dispose() {
    _incomeGoalController.dispose();
    _savingsGoalController.dispose();
    _budgetGoalController.dispose();
    super.dispose();
  }
}
