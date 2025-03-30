// lib/screens/edit_income/recurring_income_edit_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/income.dart';
import '../../services/database_helper.dart';
import '../../services/recurring_service.dart';

class RecurringIncomeEditPage extends StatefulWidget {
  final Income income;

  const RecurringIncomeEditPage({
    super.key,
    required this.income,
  });

  @override
  State<RecurringIncomeEditPage> createState() =>
      _RecurringIncomeEditPageState();
}

class _RecurringIncomeEditPageState extends State<RecurringIncomeEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late DateTime _selectedDateTime; // Keep for reference but don't allow editing
  late bool _isRecurring;
  late String _repeatFrequency;
  late String _endOption;
  DateTime? _endDate;
  late TextEditingController _notesController;

  final List<String> _frequencies = ['Day', 'Week', 'Bi-weekly', 'Month'];
  final List<String> _endOptions = ['Forever', 'Custom'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.income.name);
    _amountController =
        TextEditingController(text: widget.income.amount.toString());
    _selectedDateTime = widget.income.dateTime; // Only for reference
    _isRecurring = widget.income.isRecurring;
    _repeatFrequency = widget.income.repeatFrequency;
    _endOption = widget.income.endOption;
    _endDate = widget.income.endDate;
    _notesController = TextEditingController(text: widget.income.notes);
  }

  // Update all instances including past ones
  Future<void> _updateAllInstances() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Create updated income with new values but keeping original date/time
      final updatedIncome = Income(
        id: widget.income.id,
        name: _nameController.text,
        dateTime: _selectedDateTime, // Keep original date/time
        amount: double.parse(_amountController.text),
        isRecurring: _isRecurring,
        repeatFrequency: _repeatFrequency,
        endOption: _endOption,
        endDate: _endOption == 'Custom' ? _endDate : null,
        parentRecurringId: widget.income.parentRecurringId,
        notes: _notesController.text,
      );

      // First update the recurring definition itself
      await DatabaseHelper.instance.updateIncome(updatedIncome);

      // Update previous instances
      await _updatePreviousInstances(updatedIncome);

      // Force a comprehensive refresh and processing
      await RecurringService.instance
          .checkAndProcessRecurring(forceProcess: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All instances updated successfully'),
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      debugPrint('Error updating all instances: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating recurring income')),
        );
      }
    }
  }

  // Update only future instances
  Future<void> _updateFutureInstancesOnly() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Create updated income with new values but keeping original date/time
      final updatedIncome = Income(
        id: widget.income.id,
        name: _nameController.text,
        dateTime: _selectedDateTime, // Keep original date/time
        amount: double.parse(_amountController.text),
        isRecurring: _isRecurring,
        repeatFrequency: _repeatFrequency,
        endOption: _endOption,
        endDate: _endOption == 'Custom' ? _endDate : null,
        parentRecurringId: widget.income.parentRecurringId,
        notes: _notesController.text,
      );

      // Update the recurring definition itself
      await DatabaseHelper.instance.updateIncome(updatedIncome);

      // Force a comprehensive refresh and processing
      await RecurringService.instance
          .checkAndProcessRecurring(forceProcess: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Future instances updated successfully'),
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      debugPrint('Error updating future instances: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating recurring income')),
        );
      }
    }
  }

  Future<void> _updatePreviousInstances(Income updatedIncome) async {
    // Make sure we have an ID
    if (updatedIncome.id == null) {
      debugPrint('Cannot update instances for recurring income without ID');
      return;
    }

    try {
      // Get all instances of this recurring income
      final instances = await DatabaseHelper.instance
          .getRecurringIncomeInstances(updatedIncome.id!);

      final db = await DatabaseHelper.instance.database;
      int updateCount = 0;

      // Update each instance with the new values
      for (final instance in instances) {
        // Preserve the original date and time of each instance

        // Update with new values but keep original date
        await db.update(
          'income',
          {
            'name': updatedIncome.name,
            'amount': updatedIncome.amount,
            'notes': updatedIncome.notes,
            // Keep original dateTime, don't update it
          },
          where: 'id = ?',
          whereArgs: [instance.id],
        );

        updateCount++;
      }

      debugPrint('Updated $updateCount previous income instances');
    } catch (e) {
      debugPrint('Error updating previous instances: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Recurring Income'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Income name field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Income Name',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount field
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Show start date/time as read-only information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Date & Time (cannot be changed)',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, y HH:mm')
                              .format(_selectedDateTime),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Add details about this recurring income...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 300,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),

              // Recurring settings section
              const Text(
                'Recurrence Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Repeat frequency dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Repeat this every',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                dropdownColor: const Color(0xFF212121),
                style: const TextStyle(color: Colors.white),
                value: _repeatFrequency,
                items: _frequencies.map((String frequency) {
                  return DropdownMenuItem<String>(
                    value: frequency,
                    child: Text(frequency),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _repeatFrequency = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // End option section
              Row(
                children: [
                  const Text(
                    'Till:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      dropdownColor: const Color(0xFF212121),
                      style: const TextStyle(color: Colors.white),
                      value: _endOption,
                      items: _endOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _endOption = newValue;
                            if (newValue == 'Custom' && _endDate == null) {
                              _endDate =
                                  DateTime.now().add(const Duration(days: 30));
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              // End date picker (only show if custom end option is selected)
              if (_endOption == 'Custom') ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.blue,
                              surface: Color(0xFF212121),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _endDate != null
                              ? DateFormat('MMM d, y').format(_endDate!)
                              : 'Select End Date',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // Replace single save button with two action buttons
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Button for updating only future instances
            Expanded(
              child: ElevatedButton(
                onPressed: _updateFutureInstancesOnly,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Update Future Only',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Button for updating all instances
            Expanded(
              child: ElevatedButton(
                onPressed: _updateAllInstances,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Update All',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
