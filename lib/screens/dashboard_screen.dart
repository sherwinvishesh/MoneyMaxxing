// lib/screens/dashboard_screen.dart - updated version
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/financial_transaction.dart';
import '../models/profile_settings.dart';
import '../services/database_helper.dart';
import 'edit_transaction/all_transactions_edit_page.dart';
import '../informatics/widgets/budget_graph.dart';
import '../informatics/widgets/income_progress_bar.dart';
import '../services/recurring_service.dart';
import '../informatics/services/budget_data_service.dart';
import '../services/currency_service.dart';
import 'transaction_detail_screen.dart';
import '../models/category.dart' as app_models;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // Clock widget with its own state to avoid rebuilding the entire dashboard
  final _clockKey = GlobalKey<_ClockWidgetState>();

  List<FinancialTransaction> _transactions = [];
  Timer? _autoRefreshTimer; // Kept for auto-refreshing data
  ProfileSettings? _profileSettings;
  bool _isLoadingProfile = true;
  bool _isLoading = false;

  // Cache for category icons
  final Map<String, IconData> _categoryIconCache = {};

  // Keys for widgets to force refresh
  final _budgetGraphKey = GlobalKey<BudgetGraphState>();
  final _incomeProgressKey = GlobalKey<IncomeProgressBarState>();
  final Map<String, Color> _categoryColorCache = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadProfileSettings();
    _preloadCategoryIcons();

    // Add a timer for auto-refreshing financial data every 60 seconds (increased from 30)
    // This prevents too frequent UI updates that could cause glitchy appearance
    _autoRefreshTimer =
        Timer.periodic(const Duration(minutes: 1), (Timer timer) {
      _refreshDataSilently();
      debugPrint('Auto-refreshed financial data silently');
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // Preload category icons for faster rendering
  Future<void> _preloadCategoryIcons() async {
    try {
      final categories = await DatabaseHelper.instance.getAllCategories();
      for (final category in categories) {
        _categoryIconCache[category.name] = category.icon;
      }
      debugPrint('Preloaded ${categories.length} category icons');
    } catch (e) {
      debugPrint('Error preloading category icons: $e');
    }
  }

  // Get icon for a specific category
  Future<IconData> _getCategoryIcon(FinancialTransaction transaction) async {
    if (transaction.isIncome) {
      return Icons.account_balance; // Default icon for income
    }

    if (transaction.category != null) {
      // First check the cache
      if (_categoryIconCache.containsKey(transaction.category)) {
        return _categoryIconCache[transaction.category]!;
      }

      // If not in cache, fetch from database
      try {
        final categories = await DatabaseHelper.instance.getAllCategories();
        for (final category in categories) {
          if (category.name == transaction.category) {
            // Store in cache for future use
            _categoryIconCache[category.name] = category.icon;
            return category.icon;
          }
        }
      } catch (e) {
        debugPrint('Error fetching category icon: $e');
      }
    }

    // Default icon if category not found
    return Icons.shopping_cart;
  }

  Future<Color> _getCategoryColor(String? categoryName) async {
    if (categoryName == null) return Colors.blue;

    // First check the cache
    if (_categoryColorCache.containsKey(categoryName)) {
      return _categoryColorCache[categoryName]!;
    }

    // If not in cache, fetch from database
    try {
      final categories = await DatabaseHelper.instance.getAllCategories();
      for (final category in categories) {
        // Store in cache for future use
        _categoryColorCache[category.name] = category.color;

        if (category.name == categoryName) {
          return category.color;
        }
      }
    } catch (e) {
      debugPrint('Error fetching category color: $e');
    }

    return Colors.blue; // Default fallback
  }

  // Silent refresh that doesn't set loading state to avoid UI flickering
  Future<void> _refreshDataSilently() async {
    if (!mounted) return;

    try {
      // Process any recurring transactions first
      await RecurringService.instance
          .checkAndProcessRecurring(forceProcess: false);

      // Then load the latest transactions without setting loading state
      await _loadTransactions();

      // Refresh the graphs without animation
      _budgetGraphKey.currentState?.refreshData();
      _incomeProgressKey.currentState?.refreshData();

      // Clear any cached data in the BudgetDataService
      await BudgetDataService.instance.forceRefresh();
    } catch (e) {
      debugPrint('Error refreshing dashboard silently: $e');
    }
  }

  Future<void> refreshExpenditures() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Force process any recurring transactions first
      await RecurringService.instance
          .checkAndProcessRecurring(forceProcess: true);

      // Then load the latest transactions
      await _loadTransactions();

      // Refresh profile settings
      await _loadProfileSettings();

      // Also refresh the graphs
      _budgetGraphKey.currentState?.refreshData();
      _incomeProgressKey.currentState?.refreshData();

      // Clear any cached data in the BudgetDataService
      await BudgetDataService.instance.forceRefresh();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileSettings() async {
    try {
      final profileSettings =
          await DatabaseHelper.instance.getProfileSettings();

      if (mounted) {
        setState(() {
          _profileSettings = profileSettings;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile settings: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      // Use the DatabaseHelper directly to get the most current data
      final transactions =
          await DatabaseHelper.instance.getLatestTransactions(5);

      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }

  void _navigateToTransactionDetail(FinancialTransaction transaction) async {
    final hasChanges = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(
          transaction: transaction,
        ),
      ),
    );

    if (hasChanges == true) {
      refreshExpenditures();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyMaxxing'),
        centerTitle: false,
        backgroundColor: Colors.black,
        actions: [
          // Optional refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data...'),
                  duration: Duration(seconds: 1),
                ),
              );
              refreshExpenditures();
            },
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshExpenditures,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalized greeting
              _isLoadingProfile
                  ? const Text(
                      'Welcome User',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      'Welcome, ${_profileSettings?.getDisplayName() ?? "User"}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              // Replace the direct time string with a self-updating clock widget
              ClockWidget(key: _clockKey),
              const SizedBox(height: 20),

              // Budget Graph with integrated stats and a key for refreshing
              BudgetGraph(
                key: _budgetGraphKey,
                timeString: _clockKey.currentState?.timeString ??
                    DateFormat('hh:mm a').format(DateTime.now()),
                onRefreshCompleted: () {
                  debugPrint('Budget graph refresh completed');
                },
              ),

              const SizedBox(height: 20),

              // Recent Transactions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final hasChanges = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllTransactionsEditPage(),
                        ),
                      );
                      if (hasChanges == true) {
                        await refreshExpenditures();
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('See All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _transactions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];

                        return Card(
                          child: ListTile(
                            leading: FutureBuilder<IconData>(
                              future: _getCategoryIcon(transaction),
                              builder: (context, iconSnapshot) {
                                final iconData = iconSnapshot.data ??
                                    (transaction.isIncome
                                        ? Icons.account_balance
                                        : Icons.shopping_cart);

                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .black, // Black background for icons
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1),
                                  ),
                                  child: FutureBuilder<Color>(
                                    future: transaction.isIncome
                                        ? Future.value(Colors.green)
                                        : _getCategoryColor(
                                            transaction.category),
                                    builder: (context, colorSnapshot) {
                                      return Icon(
                                        iconData,
                                        color:
                                            colorSnapshot.data ?? Colors.blue,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            title: Text(transaction.name),
                            subtitle: transaction.category != null
                                ? Text(transaction.category!)
                                : Text(transaction.isIncome ? 'Income' : ''),
                            trailing: FutureBuilder<String>(
                              future: transaction.getAmountDisplay(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }

                                final formattedAmount = snapshot.data ?? '';

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formattedAmount,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: transaction.getAmountColor(),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d, y hh:mm a')
                                          .format(transaction.dateTime),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              },
                            ),
                            onTap: () =>
                                _navigateToTransactionDetail(transaction),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 20),

              // New Income Progress Bar
              IncomeProgressBar(
                key: _incomeProgressKey,
                onRefreshCompleted: () {
                  debugPrint('Income progress refresh completed');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate widget to handle clock updates independently
class ClockWidget extends StatefulWidget {
  const ClockWidget({Key? key}) : super(key: key);

  @override
  _ClockWidgetState createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late String timeString;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    timeString = _formatDateTime(DateTime.now());

    // Update time every minute instead of every second
    // This reduces UI rebuilds while still keeping time reasonably accurate
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      timeString = _formatDateTime(DateTime.now());
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      timeString,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.grey,
      ),
    );
  }
}
