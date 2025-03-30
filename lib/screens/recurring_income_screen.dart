// lib/screens/recurring_income_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/database_helper.dart';
import 'edit_income/recurring_income_edit_page.dart';

class RecurringIncomeScreen extends StatefulWidget {
  const RecurringIncomeScreen({super.key});

  @override
  State<RecurringIncomeScreen> createState() => _RecurringIncomeScreenState();
}

class _RecurringIncomeScreenState extends State<RecurringIncomeScreen> {
  List<Income> _recurringIncomes = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadRecurringIncomes();
  }

  Future<void> _loadRecurringIncomes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get recurring incomes
      final recurringIncomes =
          await DatabaseHelper.instance.getRecurringIncomes();

      if (mounted) {
        setState(() {
          _recurringIncomes = recurringIncomes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recurring incomes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          content:
              Text('Are you sure you want to delete this recurring income?\n\n'
                  'This will also delete all future occurrences.'),
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
        await _loadRecurringIncomes();

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
      await _loadRecurringIncomes();
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
          title: const Text('Recurring Income'),
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
    if (_recurringIncomes.isEmpty) {
      return const Center(
        child: Text(
          'No recurring income yet',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildIncomeList(),
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
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(
                Icons.repeat,
                color: Colors.white,
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
                  'First occurrence: ${DateFormat('MMM d, y').format(income.dateTime)}',
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
}
