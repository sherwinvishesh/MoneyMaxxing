// lib/screens/transaction_detail_screen.dart - updated version
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_transaction.dart';
import '../models/expenditure.dart';
import '../models/income.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import 'edit_transaction/edit_expenditure_page.dart';
import 'edit_transaction/edit_income_page.dart';

class TransactionDetailScreen extends StatefulWidget {
  final FinancialTransaction transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = false;

  // Full transaction data
  Expenditure? _expenditure;
  Income? _income;

  // Category icon
  IconData? _categoryIcon;
  Color _categoryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadFullTransactionData();
    _loadCategoryIcon();
  }

  Future<void> _loadCategoryIcon() async {
    if (widget.transaction.isIncome) {
      setState(() {
        _categoryIcon = Icons.account_balance;
        _categoryColor = Colors.green; // Default color for income
      });
      return;
    }

    if (widget.transaction.category != null) {
      try {
        final categories = await DatabaseHelper.instance.getAllCategories();
        for (final category in categories) {
          if (category.name == widget.transaction.category) {
            if (mounted) {
              setState(() {
                _categoryIcon = category.icon;
                _categoryColor =
                    category.color; // Get the color from the category
              });
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading category icon: $e');
      }
    }

    // Default icon and color
    setState(() {
      _categoryIcon = Icons.shopping_cart;
      _categoryColor = Colors.blue; // Default color
    });
  }

  Future<void> _loadFullTransactionData() async {
    if (widget.transaction.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.transaction.isIncome) {
        // Load full income data
        final incomes = await DatabaseHelper.instance.getAllIncomes();
        _income = incomes.firstWhere(
          (i) => i.id == widget.transaction.id,
          orElse: () => throw Exception('Income not found'),
        );
      } else {
        // Load full expenditure data
        final expenditures = await DatabaseHelper.instance.getAllExpenditures();
        _expenditure = expenditures.firstWhere(
          (e) => e.id == widget.transaction.id,
          orElse: () => throw Exception('Expenditure not found'),
        );
      }
    } catch (e) {
      debugPrint('Error loading transaction details: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading transaction details')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editTransaction() async {
    if (widget.transaction.id == null) return;

    bool? hasChanges;

    if (widget.transaction.isIncome && _income != null) {
      // Edit income
      hasChanges = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => EditIncomePage(
            income: _income!,
          ),
        ),
      );
    } else if (!widget.transaction.isIncome && _expenditure != null) {
      // Edit expenditure
      hasChanges = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => EditExpenditurePage(
            expenditure: _expenditure!,
            isRecurring: _expenditure!.isRecurring,
          ),
        ),
      );
    }

    if (hasChanges == true) {
      // Refresh data
      await _loadFullTransactionData();
      await _loadCategoryIcon();
    }
  }

  Future<void> _confirmAndDeleteTransaction() async {
    if (widget.transaction.id == null) return;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete this ${widget.transaction.isIncome ? 'income' : 'expense'}?'),
          actions: [
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

    if (confirmed == true) {
      try {
        if (widget.transaction.isIncome) {
          await DatabaseHelper.instance.deleteIncome(widget.transaction.id!);
        } else {
          await DatabaseHelper.instance
              .deleteExpenditure(widget.transaction.id!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
          // Return true to indicate changes were made
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint('Error deleting transaction: $e');
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
            widget.transaction.isIncome ? 'Income Details' : 'Expense Details'),
        centerTitle: true,
        backgroundColor: Colors.black,
        // No action buttons in the app bar anymore
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Main content in scrollable area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center everything
                      children: [
                        // Transaction Card - Centered
                        _buildTransactionCard(),

                        const SizedBox(height: 24),

                        // Transaction Details
                        if (widget.transaction.isIncome)
                          _buildIncomeDetails()
                        else
                          _buildExpenditureDetails(),
                      ],
                    ),
                  ),
                ),

                // Bottom action buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Edit button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          onPressed: _editTransaction,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          onPressed: _confirmAndDeleteTransaction,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

// Updated _buildTransactionCard method in lib/screens/transaction_detail_screen.dart
  Widget _buildTransactionCard() {
    return Card(
      color: const Color(0xFF212121),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Transaction Type Icon - Using the container with black background
            Container(
              width: 56, // Larger for the detail screen
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black, // Black background
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
              child: Icon(
                _categoryIcon ??
                    (widget.transaction.isIncome
                        ? Icons.account_balance
                        : Icons.shopping_cart),
                color:
                    widget.transaction.isIncome ? Colors.green : _categoryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Transaction Name
            Text(
              widget.transaction.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Transaction Category (if applicable)
            if (widget.transaction.category != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.transaction.category!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Transaction Amount
            FutureBuilder<String>(
              future: widget.transaction.getAmountDisplay(),
              builder: (context, snapshot) {
                final amountText = snapshot.data ?? '';
                return Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.transaction.isIncome
                        ? Colors.green
                        : Colors.white,
                  ),
                );
              },
            ),

            const SizedBox(height: 6),

            // Transaction Date & Time
            Text(
              DateFormat('EEEE, MMM d, y • h:mm a')
                  .format(widget.transaction.dateTime),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenditureDetails() {
    if (_expenditure == null) {
      return const Center(
        child: Text(
          'Expense details not available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
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
            // Center the title
            const Center(
              child: Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Show recurring status if applicable
            if (_expenditure!.isRecurring ||
                _expenditure!.parentRecurringId != null)
              _buildDetailRow(
                'Recurring Status',
                _expenditure!.isRecurring
                    ? 'Recurring definition'
                    : 'Recurring instance',
              ),

            // Recurring pattern if applicable
            if (_expenditure!.isRecurring)
              _buildDetailRow(
                'Recurrence Pattern',
                _expenditure!.getRecurrenceDescription(),
              ),

            // Notes if provided
            if (_expenditure!.notes.isNotEmpty)
              _buildDetailRow('Notes', _expenditure!.notes),

            // Removed Transaction ID
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeDetails() {
    if (_income == null) {
      return const Center(
        child: Text(
          'Income details not available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
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
            // Center the title
            const Center(
              child: Text(
                'Income Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Show recurring status if applicable
            if (_income!.isRecurring || _income!.parentRecurringId != null)
              _buildDetailRow(
                'Recurring Status',
                _income!.isRecurring
                    ? 'Recurring definition'
                    : 'Recurring instance',
              ),

            // Recurring pattern if applicable
            if (_income!.isRecurring)
              _buildDetailRow(
                'Recurrence Pattern',
                _income!.getRecurrenceDescription(),
              ),

            // Notes if provided
            if (_income!.notes.isNotEmpty)
              _buildDetailRow('Notes', _income!.notes),

            // Removed Transaction ID
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
