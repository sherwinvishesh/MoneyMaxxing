// lib/screens/smart_spend_result_page.dart
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/database_helper.dart';
import '../models/budget_settings.dart';

class SmartSpendResultPage extends StatefulWidget {
  final String itemName;
  final double cost;
  final double oldDailyPurchaseRate;
  final double newDailyPurchaseRate;
  final double budgetUsagePercent;
  final double desireRating;
  final double remainingBudget;

  const SmartSpendResultPage({
    Key? key,
    required this.itemName,
    required this.cost,
    required this.oldDailyPurchaseRate,
    required this.newDailyPurchaseRate,
    required this.budgetUsagePercent,
    required this.remainingBudget,
    this.desireRating = 5.0,
  }) : super(key: key);

  @override
  State<SmartSpendResultPage> createState() => _SmartSpendResultPageState();
}

class _SmartSpendResultPageState extends State<SmartSpendResultPage> {
  String _geminiAdvice = 'Analyzing your purchase...';
  bool _isLoadingAdvice = true;

  @override
  void initState() {
    super.initState();
    _getGeminiAdvice();
  }

  Map<String, String> _parseGeminiResponse(String response) {
    final result = <String, String>{};

    // Look for Rating: part
    final ratingMatch = RegExp(r'Rating:\s*(\d+/10)').firstMatch(response);
    if (ratingMatch != null) {
      result['rating'] = ratingMatch.group(1) ?? 'N/A';
    } else {
      result['rating'] = 'N/A';
    }

    // Look for Explanation: part
    final explanationMatch =
        RegExp(r'Explanation:\s*(.+)$', dotAll: true).firstMatch(response);
    if (explanationMatch != null) {
      result['explanation'] =
          explanationMatch.group(1)?.trim() ?? 'No explanation provided.';
    } else {
      result['explanation'] = 'No explanation provided.';
    }

    return result;
  }

  Future<void> _getGeminiAdvice() async {
    try {
      // Call Gemini API through our service
      final advice = await GeminiService.instance.getPurchaseAdvice(
        itemName: widget.itemName,
        cost: widget.cost,
        remainingBudget: widget.remainingBudget,
        desireRating: widget.desireRating,
      );

      if (mounted) {
        setState(() {
          _geminiAdvice = advice;
          _isLoadingAdvice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _geminiAdvice = 'Unable to get AI advice at this time.';
          _isLoadingAdvice = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format values
    final String costString = widget.cost.toStringAsFixed(2);
    final String oldDprString = widget.oldDailyPurchaseRate.toStringAsFixed(2);
    final String newDprString = widget.newDailyPurchaseRate.toStringAsFixed(2);
    final String usageString = widget.budgetUsagePercent.toStringAsFixed(1);
    final double dprChangePercent = widget.oldDailyPurchaseRate > 0
        ? ((widget.newDailyPurchaseRate - widget.oldDailyPurchaseRate) /
                widget.oldDailyPurchaseRate *
                100)
            .abs()
        : 0;
    final String dprChangeString = dprChangePercent.toStringAsFixed(1);
    final bool isDprDecrease =
        widget.newDailyPurchaseRate < widget.oldDailyPurchaseRate;

    // Determine the impact level for color coding
    Color budgetImpactColor;
    String budgetImpactText;
    if (widget.budgetUsagePercent < 2) {
      budgetImpactColor = Colors.green;
      budgetImpactText = "Very Low Impact";
    } else if (widget.budgetUsagePercent < 5) {
      budgetImpactColor = Colors.green.shade700;
      budgetImpactText = "Low Impact";
    } else if (widget.budgetUsagePercent < 10) {
      budgetImpactColor = Colors.amber;
      budgetImpactText = "Moderate Impact";
    } else if (widget.budgetUsagePercent < 20) {
      budgetImpactColor = Colors.orange;
      budgetImpactText = "Significant Impact";
    } else {
      budgetImpactColor = Colors.red;
      budgetImpactText = "High Impact";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Purchase Analysis'),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Purchase Summary Card
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
                      // Item icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.blue,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Item name (title case)
                      Text(
                        widget.itemName
                            .split(' ')
                            .map((word) => word.isNotEmpty
                                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                : '')
                            .join(' '),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Cost
                      Text(
                        '\$$costString',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Gemini AI Advice Card
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
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.purple,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'AI Purchase Advice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Gemini badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.purple,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Gemini',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gemini advice - REPLACED WITH NEW VERSION
                      _isLoadingAdvice
                          ? const Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.purple),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Getting AI insights...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rating block
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.purple.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Rating: ",
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _parseGeminiResponse(
                                                _geminiAdvice)['rating'] ??
                                            'N/A',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Explanation block
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.purple.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Explanation:",
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _parseGeminiResponse(
                                                _geminiAdvice)['explanation'] ??
                                            'No explanation provided',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // DPR Impact Card
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
                          const Icon(
                            Icons.timeline,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Daily Purchase Rate Impact',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // DPR Before and After comparison
                      Row(
                        children: [
                          // Before column
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'BEFORE',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$$oldDprString',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'per day',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Arrow
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.grey,
                            size: 24,
                          ),

                          // After column
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'AFTER',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$$newDprString',
                                  style: TextStyle(
                                    color: isDprDecrease
                                        ? Colors.red
                                        : Colors.green,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'per day',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Change percentage indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDprDecrease
                              ? Colors.red.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDprDecrease
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isDprDecrease ? Colors.red : Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$dprChangeString% ${isDprDecrease ? 'decrease' : 'increase'}',
                              style: TextStyle(
                                color:
                                    isDprDecrease ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Divider(color: Colors.grey),

                      const SizedBox(height: 16),

                      // Explanation
                      Text(
                        isDprDecrease
                            ? 'This purchase will temporarily reduce your daily spending allowance by \$$dprChangeString per day.'
                            : 'Your daily spending rate would remain stable after this purchase.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Budget Usage Card
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
                          Icon(
                            Icons.account_balance_wallet,
                            color: budgetImpactColor,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Budget Impact',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Budget percentage
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  budgetImpactText,
                                  style: TextStyle(
                                    color: budgetImpactColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This purchase is about $usageString% of your monthly budget',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              border: Border.all(
                                color: budgetImpactColor,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$usageString%',
                                style: TextStyle(
                                  color: budgetImpactColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.budgetUsagePercent / 100,
                          backgroundColor: Colors.grey[800],
                          color: budgetImpactColor,
                          minHeight: 8,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Advice text
                      const Text(
                        'The lower the budget impact, the less it affects your financial goals. Consider if this purchase aligns with your priorities.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
