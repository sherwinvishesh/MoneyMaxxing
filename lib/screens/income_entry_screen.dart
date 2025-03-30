// lib/screens/income_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/database_helper.dart';
import '../services/recurring_service.dart';

class IncomeEntryScreen extends StatefulWidget {
  const IncomeEntryScreen({super.key});

  @override
  State<IncomeEntryScreen> createState() => _IncomeEntryScreenState();
}

class _IncomeEntryScreenState extends State<IncomeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  bool _isRecurring = false;
  String _repeatFrequency = 'Month';
  String _endOption = 'Forever';
  DateTime? _endDate;
  final _notesController = TextEditingController();

  final List<String> _frequencies = ['Day', 'Week', 'Bi-weekly', 'Month'];
  final List<String> _endOptions = ['Forever', 'Custom'];

  // Add this method to check if time is in the future
  bool _isTimeInFuture(DateTime dateTime) {
    final now = DateTime.now();

    // If it's a future date, time doesn't matter
    if (dateTime.year > now.year ||
        (dateTime.year == now.year && dateTime.month > now.month) ||
        (dateTime.year == now.year &&
            dateTime.month == now.month &&
            dateTime.day > now.day)) {
      return false;
    }

    // If it's today, check if time is in the future
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return dateTime.isAfter(now);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Income'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(
                context, false); // Return false to indicate no changes
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Income Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Income Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }

                    final number = double.tryParse(value);
                    if (number == null) {
                      return 'Please enter a valid number';
                    }

                    if (number <= 0) {
                      return 'Please enter a positive amount';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date & Time'),
                  subtitle: Text(
                    DateFormat('MMM d, y HH:mm').format(_selectedDateTime),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                      );
                      if (time != null) {
                        final newDateTime = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          time.hour,
                          time.minute,
                        );

                        // Check if the time is in the future
                        if (_isTimeInFuture(newDateTime)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cannot select a future time for today\'s date'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          setState(() {
                            _selectedDateTime = newDateTime;
                          });
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add details about this income...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 300,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Recurring Income'),
                  value: _isRecurring,
                  onChanged: (bool value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                  activeColor: Colors.blue,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Repeat this every',
                            border: OutlineInputBorder(),
                          ),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Till:',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
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
                                  _endDate = DateTime.now()
                                      .add(const Duration(days: 30));
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
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
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _endDate != null
                                  ? DateFormat('MMM d, y').format(_endDate!)
                                  : 'Select End Date',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                // If it's not recurring, create a simple income entry
                if (!_isRecurring) {
                  // Regular, one-time income
                  final income = Income(
                    name: _nameController.text,
                    dateTime: _selectedDateTime,
                    amount: double.parse(_amountController.text),
                    isRecurring: false,
                    notes: _notesController.text, // Optional notes
                  );

                  // Save to database and get the ID
                  final id = await DatabaseHelper.instance.insertIncome(income);
                  debugPrint('Saved regular income with ID: $id');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Income saved successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                } else {
                  // Handle recurring income differently

                  // Step 1: Create recurring definition with pattern information
                  final recurringDefinition = Income(
                    name: _nameController.text,
                    dateTime: _selectedDateTime,
                    amount: double.parse(_amountController.text),
                    isRecurring: true,
                    repeatFrequency: _repeatFrequency,
                    endOption: _endOption,
                    endDate: _endOption == 'Custom' ? _endDate : null,
                    notes: _notesController.text,
                  );

                  // Save the recurring definition
                  final definitionId = await DatabaseHelper.instance
                      .insertIncome(recurringDefinition);
                  debugPrint(
                      'Saved recurring definition with ID: $definitionId');

                  // Special handle for the first instance - we don't want duplicates
                  // First, check if an instance for this date/time already exists
                  final existingIncomes =
                      await DatabaseHelper.instance.getAllIncomes();
                  bool foundDuplicate = false;

                  for (var existing in existingIncomes) {
                    if (existing.name == _nameController.text &&
                        existing.amount ==
                            double.parse(_amountController.text) &&
                        existing.dateTime.year == _selectedDateTime.year &&
                        existing.dateTime.month == _selectedDateTime.month &&
                        existing.dateTime.day == _selectedDateTime.day &&
                        existing.dateTime.hour == _selectedDateTime.hour &&
                        existing.dateTime.minute == _selectedDateTime.minute) {
                      foundDuplicate = true;
                      debugPrint(
                          'Found existing instance matching the first occurrence, skipping creation');
                      break;
                    }
                  }

                  // Only create the first instance if no duplicate exists
                  if (!foundDuplicate) {
                    // Create the first instance explicitly
                    final firstInstance = Income(
                      name: _nameController.text,
                      dateTime: _selectedDateTime,
                      amount: double.parse(_amountController.text),
                      isRecurring: false,
                      parentRecurringId: definitionId,
                      notes: _notesController.text,
                    );

                    // Save the first instance
                    final instanceId = await DatabaseHelper.instance
                        .insertIncome(firstInstance);
                    debugPrint(
                        'Saved first income instance with ID: $instanceId');
                  }

                  // Create a copy of the definition with its ID for processing future instances
                  final definitionWithId =
                      recurringDefinition.copyWith(id: definitionId);

                  // Now process FUTURE instances (after the original date)
                  await RecurringService.instance
                      .processNewRecurringIncome(definitionWithId);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recurring income saved'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                }
              } catch (e) {
                debugPrint('Error saving income: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error saving income')),
                  );
                }
              }
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Save Income'),
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
