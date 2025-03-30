// lib/screens/recurring_transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expenditure.dart';
import '../models/income.dart';
import '../services/database_helper.dart';
import 'edit_income/recurring_income_edit_page.dart';
import 'edit_expenditure/recurring_expenditure_edit_page.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  List<Expenditure> _recurringExpenditures = [];
  List<Income> _recurringIncomes = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  // Cache for category icons
  final Map<String, IconData> _categoryIconCache = {};
  final Map<String, Color> _categoryColorCache = {};

  @override
  void initState() {
    super.initState();
    _loadRecurringTransactions();
    _preloadCategoryIcons();
  }

  // Preload category icons for faster rendering
  Future<void> _preloadCategoryIcons() async {
    try {
      final categories = await DatabaseHelper.instance.getAllCategories();
      for (final category in categories) {
        _categoryIconCache[category.name] = category.icon;
        _categoryColorCache[category.name] = category.color;
      }
      debugPrint('Preloaded ${categories.length} category icons');
    } catch (e) {
      debugPrint('Error preloading category icons: $e');
    }
  }

  // Get icon for a specific expense category
  IconData getCategoryIcon(String categoryName) {
    // Check if in cache
    if (_categoryIconCache.containsKey(categoryName)) {
      return _categoryIconCache[categoryName]!;
    }

    // Default icon if not found
    return Icons.shopping_cart;
  }

  Future<Color> _getCategoryColor(String categoryName) async {
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

  Future<void> _loadRecurringTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get recurring expenses
      final recurringExpenses =
          await DatabaseHelper.instance.getRecurringExpenditures();

      // Get recurring incomes
      final recurringIncomes =
          await DatabaseHelper.instance.getRecurringIncomes();

      if (mounted) {
        setState(() {
          _recurringExpenditures = recurringExpenses;
          _recurringIncomes = recurringIncomes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recurring transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRecurringExpense(Expenditure expense) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete this recurring expense?\n\n'
              'Past occurrences will be preserved, but future ones will be canceled.'),
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

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteExpenditure(expense.id!);

        _hasChanges = true;
        await _loadRecurringTransactions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring expense deleted')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting recurring expense: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting recurring expense')),
          );
        }
      }
    }
  }

  Future<void> _deleteRecurringIncome(Income income) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete this recurring income?\n\n'
              'Past occurrences will be preserved, but future ones will be canceled.'),
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

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteIncome(income.id!);

        _hasChanges = true;
        await _loadRecurringTransactions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring income deleted')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting recurring income: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting recurring income')),
          );
        }
      }
    }
  }

  Future<void> _editRecurringIncome(Income income) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecurringIncomeEditPage(
          income: income,
        ),
      ),
    );

    if (result == true) {
      _hasChanges = true;
      await _loadRecurringTransactions();
    }
  }

  Future<void> _editRecurringExpense(Expenditure expense) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecurringExpenditureEditPage(
          expenditure: expense,
        ),
      ),
    );

    if (result == true) {
      _hasChanges = true;
      await _loadRecurringTransactions();
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
          title: const Text('Recurring Transactions'),
          centerTitle: true,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _hasChanges);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Recurring Income',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_recurringIncomes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No recurring income yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
          else
            _buildIncomeList(),

          const Divider(color: Color(0xFF2C2C2E), thickness: 1, height: 32),

          // Expenses section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Recurring Expenses',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_recurringExpenditures.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No recurring expenses yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
          else
            _buildExpensesList(),
        ],
      ),
    );
  }

  Widget _buildIncomeList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recurringIncomes.length,
      itemBuilder: (context, index) {
        final income = _recurringIncomes[index];
        return Card(
          color: const Color(0xFF212121),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black, // Black background
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
              child: Icon(
                Icons.account_balance,
                color: Colors.green,
              ),
            ),
            title: Text(
              income.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${income.getRecurrenceDescription()} • \$${income.amount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  'First occurrence: ${DateFormat('MMM d, y HH:mm').format(income.dateTime)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add edit button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 24),
                  onPressed: () => _editRecurringIncome(income),
                ),
                // Keep delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                  onPressed: () => _deleteRecurringIncome(income),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recurringExpenditures.length,
      itemBuilder: (context, index) {
        final expense = _recurringExpenditures[index];
        return Card(
          color: const Color(0xFF212121),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black, // Black background
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
              child: FutureBuilder<Color>(
                  future: _getCategoryColor(expense.category),
                  builder: (context, snapshot) {
                    final color = snapshot.data ?? Colors.blue;
                    return Icon(
                      getCategoryIcon(expense.category),
                      color: color,
                    );
                  }),
            ),
            title: Text(
              expense.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${expense.getRecurrenceDescription()} • \$${expense.cost.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.blue),
                ),
                Text(
                  'First occurrence: ${DateFormat('MMM d, y HH:mm').format(expense.dateTime)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add edit button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 24),
                  onPressed: () => _editRecurringExpense(expense),
                ),
                // Keep delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                  onPressed: () => _deleteRecurringExpense(expense),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
