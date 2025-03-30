// lib/screens/edit_income/all_incomes_edit_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/income.dart';
import '../../services/database_helper.dart';
import 'selected_income_edit_page.dart';

class AllIncomesEditPage extends StatefulWidget {
  const AllIncomesEditPage({super.key});

  @override
  State<AllIncomesEditPage> createState() => _AllIncomesEditPageState();
}

class _AllIncomesEditPageState extends State<AllIncomesEditPage> {
  List<Income> _incomes = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    final incomes = await DatabaseHelper.instance.getAllIncomes();
    if (mounted) {
      setState(() {
        _incomes = incomes;
      });
    }
  }

  Future<void> _deleteIncome(Income income) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this income entry?'),
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
        await _loadIncomes(); // Reload the current list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting income')),
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
          title: const Text('Edit Incomes'),
          centerTitle: true,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _hasChanges);
            },
          ),
        ),
        body: _incomes.isEmpty
            ? const Center(
                child: Text(
                  'No income entries available',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _incomes.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final income = _incomes[index];
                  return Card(
                    color: const Color(0xFF212121),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        income.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, y hh:mm a').format(income.dateTime),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${income.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green, // Green for income
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue, size: 20),
                            onPressed: () async {
                              final hasChanges = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SelectedIncomeEditPage(
                                    income: income,
                                  ),
                                ),
                              );

                              if (hasChanges == true) {
                                _hasChanges = true;
                                await _loadIncomes();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.red, size: 20),
                            onPressed: () => _deleteIncome(income),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
