// lib/screens/edit_transaction/all_transactions_edit_page.dart - updated version
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expenditure.dart';
import '../../models/income.dart';
import '../../models/financial_transaction.dart';
import '../../services/database_helper.dart';
import 'edit_expenditure_page.dart';
import 'edit_income_page.dart';
import '../transaction_detail_screen.dart';

class AllTransactionsEditPage extends StatefulWidget {
  const AllTransactionsEditPage({super.key});

  @override
  State<AllTransactionsEditPage> createState() =>
      _AllTransactionsEditPageState();
}

class _AllTransactionsEditPageState extends State<AllTransactionsEditPage> {
  List<FinancialTransaction> _transactions = [];
  List<FinancialTransaction> _filteredTransactions = [];
  bool _hasChanges = false;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Cache for category icons
  final Map<String, IconData> _categoryIconCache = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _preloadCategoryIcons();

    // Add listener to search controller to update filtered list
    _searchController.addListener(_filterTransactions);
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

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = List.from(_transactions);
      } else {
        _filteredTransactions = _transactions.where((transaction) {
          // Search by name
          final nameMatch = transaction.name.toLowerCase().contains(query);

          // Search by date (formatted)
          final dateStr = DateFormat('MMM d, y hh:mm a')
              .format(transaction.dateTime)
              .toLowerCase();
          final dateMatch = dateStr.contains(query);

          // Search by amount
          final amountStr = transaction.amount.toString();
          final amountMatch = amountStr.contains(query);

          // Search by category if available
          bool categoryMatch = false;
          if (transaction.category != null) {
            categoryMatch = transaction.category!.toLowerCase().contains(query);
          }

          // Search by type (income/expense)
          final typeMatch =
              (transaction.isIncome && 'income'.contains(query)) ||
                  (!transaction.isIncome && 'expense'.contains(query));

          // Search by notes (we need to get the actual notes from the original objects)
          bool notesMatch = false;
          if (transaction.notes != null && transaction.notes!.isNotEmpty) {
            notesMatch = transaction.notes!.toLowerCase().contains(query);
          }

          // Combine all search criteria
          return nameMatch ||
              dateMatch ||
              amountMatch ||
              categoryMatch ||
              typeMatch ||
              notesMatch;
        }).toList();
      }
    });
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load both expenditures and incomes
      final expenditures = await DatabaseHelper.instance.getAllExpenditures();
      final incomes = await DatabaseHelper.instance.getAllIncomes();

      // Convert to unified Transaction objects
      final expenseTransactions = expenditures
          .map((e) => FinancialTransaction.fromExpenditure(e))
          .toList();

      final incomeTransactions =
          incomes.map((i) => FinancialTransaction.fromIncome(i)).toList();

      // Combine and sort by date, most recent first
      final allTransactions = [...expenseTransactions, ...incomeTransactions];
      allTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (mounted) {
        setState(() {
          _transactions = allTransactions;
          _filteredTransactions =
              List.from(allTransactions); // Initialize filtered list
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Color> _getCategoryColor(String? categoryName) async {
    if (categoryName == null) return Colors.blue;

    try {
      final categories = await DatabaseHelper.instance.getAllCategories();
      for (final category in categories) {
        if (category.name == categoryName) {
          return category.color;
        }
      }
    } catch (e) {
      debugPrint('Error fetching category color: $e');
    }

    return Colors.blue; // Default fallback
  }

  Future<void> _deleteTransaction(FinancialTransaction transaction) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete this ${transaction.isIncome ? 'income' : 'expense'}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && transaction.id != null) {
      try {
        if (transaction.isIncome) {
          // Delete income
          await DatabaseHelper.instance.deleteIncome(transaction.id!);
        } else {
          // Delete expenditure
          await DatabaseHelper.instance.deleteExpenditure(transaction.id!);
        }

        _hasChanges = true;
        await _loadTransactions(); // Reload the transactions
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting transaction')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) {
                    setState(() {
                      _isSearching = false;
                    });
                  },
                )
              : const Text('Edit Transactions'),
          centerTitle: !_isSearching,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: _isSearching
                ? const Icon(Icons.close)
                : const Icon(Icons.arrow_back),
            onPressed: () {
              if (_isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              } else {
                Navigator.pop(context, _hasChanges);
              }
            },
          ),
          actions: [
            // Only show search icon when not already searching
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Search bar (when not in app bar)
                  if (!_isSearching)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name, date, amount, notes...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF212121),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                  // Results count when searching
                  if (_searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Text(
                            'Found ${_filteredTransactions.length} result${_filteredTransactions.length != 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // Transaction list
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isNotEmpty
                                  ? 'No results found'
                                  : 'No transactions available',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredTransactions.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];

                              return Card(
                                color: const Color(0xFF212121),
                                margin: const EdgeInsets.only(bottom: 12),
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
                                          color:
                                              Colors.black, // Black background
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
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
                                              color: colorSnapshot.data ??
                                                  Colors.blue,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  title: Text(
                                    transaction.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (transaction.category != null)
                                        Text(
                                          transaction.category!,
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      Text(
                                        DateFormat('MMM d, y hh:mm a')
                                            .format(transaction.dateTime),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                      if (transaction.notes != null &&
                                          transaction.notes!.isNotEmpty)
                                        Text(
                                          transaction.notes!.length > 40
                                              ? '${transaction.notes!.substring(0, 40)}...'
                                              : transaction.notes!,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                  trailing: FutureBuilder<String>(
                                    future: transaction.getAmountDisplay(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }

                                      final displayAmount = snapshot.data ?? '';

                                      return Text(
                                        displayAmount,
                                        style: TextStyle(
                                          color: transaction.isIncome
                                              ? Colors.green
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  isThreeLine: transaction.notes != null &&
                                      transaction.notes!.isNotEmpty,
                                  onTap: () async {
                                    final hasChanges =
                                        await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TransactionDetailScreen(
                                          transaction: transaction,
                                        ),
                                      ),
                                    );

                                    if (hasChanges == true) {
                                      _hasChanges = true;
                                      await _loadTransactions();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
