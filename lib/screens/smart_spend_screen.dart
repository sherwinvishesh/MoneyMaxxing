// lib/screens/smart_spend_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/currency_service.dart';
import '../services/database_helper.dart';
import '../models/budget_settings.dart';
import '../informatics/services/daily_purchase_rate_service.dart';
import 'smart_spend_result_page.dart';
// In lib/screens/smart_spend_screen.dart, add this import at the top:
import '../models/financial_transaction.dart';

class SmartSpendScreen extends StatefulWidget {
  const SmartSpendScreen({Key? key}) : super(key: key);

  @override
  State<SmartSpendScreen> createState() => _SmartSpendScreenState();
}

class _SmartSpendScreenState extends State<SmartSpendScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _costController = TextEditingController();
  final _paymentsController = TextEditingController();

  bool _isLoading = false;
  double _dailyPurchaseRate = 0.0;
  String _currencySymbol = '\$';

  // Tab controller for single and multiple payment options
  late TabController _tabController;

  // For multiple payments
  String _paymentFrequency = 'Month';
  final List<String> _frequencies = ['Day', 'Week', 'Bi-weekly', 'Month'];

  // Desire rating (1-10)
  double _desireRating = 5.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _paymentsController.text = '1';

    _loadCurrency();
    _loadDailyPurchaseRate();

    // Listen for tab changes to update UI
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _costController.dispose();
    _paymentsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    try {
      final symbol = await CurrencyService.instance.getCurrencySymbol();
      if (mounted) {
        setState(() {
          _currencySymbol = symbol;
        });
      }
    } catch (e) {
      debugPrint('Error loading currency: $e');
    }
  }

  Future<void> _loadDailyPurchaseRate() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final dpr = await DailyPurchaseRateService.instance
          .getDailyPurchaseRate(forceRefresh: true);

      if (mounted) {
        setState(() {
          _dailyPurchaseRate = dpr;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading DPR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Analyze the spending and navigate to results page
  void _analyzeSpending() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the cost from the text field
      final double cost = double.parse(_costController.text);
      double totalCost = cost;

      // For multiple payments, multiply
      if (_tabController.index == 1) {
        final int payments = int.parse(_paymentsController.text);
        totalCost = cost * payments;
      }

      // Calculate "new DPR"
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;
      final daysLeft = (daysInMonth - dayOfMonth) + 1;

      final oldDailyTotal = _dailyPurchaseRate * daysLeft;
      final double leftoverMoney =
          (oldDailyTotal - totalCost) < 0 ? 0 : (oldDailyTotal - totalCost);
      final double newDpr = leftoverMoney / daysLeft;

      // Get budget settings and calculate REMAINING budget (new!)
      final budgetSettings = await DatabaseHelper.instance.getBudgetSettings();
      final totalBudget = budgetSettings.totalBudgetGoal;

      // Calculate how much has been spent this month
      final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      final List<FinancialTransaction> thisMonthTransactions =
          await DatabaseHelper.instance
              .getTransactionsForPeriod(firstDayOfMonth, now);

      // Sum up all expenditures for this month
      double spentThisMonth = 0.0;
      for (var transaction in thisMonthTransactions) {
        if (!transaction.isIncome) {
          spentThisMonth += transaction.amount;
        }
      }

      // Calculate remaining budget
      double remainingBudget = totalBudget - spentThisMonth;
      if (remainingBudget < 0) remainingBudget = 0;

      double budgetUsagePercent = 0.0;
      if (totalBudget > 0) {
        final usageRatio = totalCost / totalBudget;
        budgetUsagePercent = usageRatio * 100;
      }

      // Navigate to the results page
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SmartSpendResultPage(
              itemName: _itemNameController.text.trim(),
              cost: totalCost,
              oldDailyPurchaseRate: _dailyPurchaseRate,
              newDailyPurchaseRate: newDpr,
              budgetUsagePercent: budgetUsagePercent,
              desireRating: _desireRating,
              remainingBudget:
                  remainingBudget, // Pass the remaining budget to the result page
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error analyzing spending: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error analyzing purchase: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SmartSpend'),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      color: const Color(0xFF212121),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    color: Colors.amber),
                                const SizedBox(width: 10),
                                Text(
                                  'What is SmartSpend?',
                                  style: TextStyle(
                                    color: Colors.grey[200],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'SmartSpend helps you make better purchase decisions by '
                              'analyzing your budget, spending patterns, and financial goals.',
                              style: TextStyle(
                                  color: Colors.grey[300], fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter what you want to buy, and we\'ll tell you if it\'s a good '
                              'financial decision right now.',
                              style: TextStyle(
                                  color: Colors.grey[300], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DPR Info Card
                    Card(
                      color: const Color(0xFF212121),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet,
                                    color: Colors.green),
                                const SizedBox(width: 10),
                                const Text(
                                  'Your Daily Spending Rate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // DPR Display
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currencySymbol,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _dailyPurchaseRate.toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    '/day',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'This is how much you can safely spend each day '
                              'based on your budget and financial goals.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Purchase Input Card
                    Card(
                      color: const Color(0xFF212121),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'What do you want to buy?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Custom TabBar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  _buildTabButton(
                                    'Single Payment',
                                    0,
                                    Icons.payment,
                                  ),
                                  _buildTabButton(
                                    'Multiple Payments',
                                    1,
                                    Icons.payments,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Item name
                            TextFormField(
                              controller: _itemNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Item Name',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade700),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.amber),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.grey),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter what you want to buy';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Cost
                            TextFormField(
                              controller: _costController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: _tabController.index == 0
                                    ? 'Cost'
                                    : 'Cost Per Payment',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade700),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.amber),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.attach_money,
                                    color: Colors.grey),
                                prefixText: '$_currencySymbol ',
                                prefixStyle:
                                    const TextStyle(color: Colors.white),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the cost';
                                }
                                final number = double.tryParse(value);
                                if (number == null) {
                                  return 'Please enter a valid number';
                                }
                                if (number <= 0) {
                                  return 'Please enter a value greater than zero';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Multiple payments fields
                            if (_tabController.index == 1) ...[
                              Row(
                                children: [
                                  // Number of payments
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _paymentsController,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Number of Payments',
                                        labelStyle:
                                            const TextStyle(color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade700),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Colors.amber),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        prefixIcon: const Icon(
                                            Icons.format_list_numbered,
                                            color: Colors.grey),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (_tabController.index != 1)
                                          return null;
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        final number = int.tryParse(value);
                                        if (number == null || number <= 0) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Payment frequency
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      value: _paymentFrequency,
                                      dropdownColor: const Color(0xFF2C2C2E),
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Frequency',
                                        labelStyle:
                                            const TextStyle(color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade700),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Colors.amber),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        prefixIcon: const Icon(
                                            Icons.calendar_today,
                                            color: Colors.grey),
                                      ),
                                      items:
                                          _frequencies.map((String frequency) {
                                        return DropdownMenuItem<String>(
                                          value: frequency,
                                          child: Text(frequency),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _paymentFrequency = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Desire rating
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.favorite,
                                          color: Colors.pink, size: 16),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'How much do you want this item?',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getDesireRatingColor()
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getDesireRatingText(),
                                          style: TextStyle(
                                            color: _getDesireRatingColor(),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 16),
                                    valueIndicatorShape:
                                        const PaddleSliderValueIndicatorShape(),
                                    valueIndicatorColor: Colors.amber,
                                    valueIndicatorTextStyle:
                                        const TextStyle(color: Colors.black),
                                    activeTrackColor: _getDesireRatingColor(),
                                    inactiveTrackColor: Colors.grey.shade800,
                                    thumbColor: _getDesireRatingColor(),
                                  ),
                                  child: Slider(
                                    value: _desireRating,
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: _desireRating.round().toString(),
                                    onChanged: (value) {
                                      setState(() {
                                        _desireRating = value;
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('1',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                      const Text('10',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Analyze button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _analyzeSpending,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.analytics, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Analyze This Purchase',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method to build tab buttons
  Widget _buildTabButton(String text, int index, IconData icon) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get color based on desire rating
  Color _getDesireRatingColor() {
    if (_desireRating <= 3) {
      return Colors.green;
    } else if (_desireRating <= 6) {
      return Colors.amber;
    } else if (_desireRating <= 8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Helper to get text based on desire rating
  String _getDesireRatingText() {
    if (_desireRating <= 3) {
      return "Could Skip";
    } else if (_desireRating <= 6) {
      return "Nice to Have";
    } else if (_desireRating <= 8) {
      return "Really Want";
    } else {
      return "Must Have";
    }
  }
}
