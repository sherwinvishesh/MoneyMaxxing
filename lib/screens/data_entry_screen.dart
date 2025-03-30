// lib/screens/data_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expenditure.dart';
// import '../models/category.dart';
import '../services/database_helper.dart';
import '../services/recurring_service.dart';
import '../models/category.dart' as app_models;

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  app_models.Category? _selectedCategory;

  bool _isRecurring = false;
  String _repeatFrequency = 'Month';
  String _endOption = 'Forever';
  DateTime? _endDate;
  final _notesController = TextEditingController();
  bool _isLoadingCategories = true;
  List<app_models.Category> _categories = [];

  final List<String> _frequencies = ['Day', 'Week', 'Bi-weekly', 'Month'];
  final List<String> _endOptions = ['Forever', 'Custom'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      final categories = await DatabaseHelper.instance.getAllCategories();

      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first;
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

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
        title: const Text('New Expense'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(
                context, false); // Return false to indicate no changes
          },
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Expense Name',
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

                      // Category dropdown with icons
                      _buildCategoryDropdown(),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(
                          labelText: 'Cost',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a cost';
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
                          DateFormat('MMM d, y HH:mm')
                              .format(_selectedDateTime),
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
                              initialTime:
                                  TimeOfDay.fromDateTime(_selectedDateTime),
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
                          hintText: 'Add details about this expense...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        maxLength: 300,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Recurring Expense'),
                        subtitle: const Text(
                          'This expense will repeat automatically',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isRecurring,
                        onChanged: (bool value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
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
                                      if (newValue == 'Custom' &&
                                          _endDate == null) {
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
                                    DateTime.now()
                                        .add(const Duration(days: 30)),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endDate != null
                                        ? DateFormat('MMM d, y')
                                            .format(_endDate!)
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
          onPressed: _saveExpense,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Save Expense'),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categories.isEmpty) {
      return Card(
        color: Colors.amber[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No Categories Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/category_settings');
                      },
                      child: const Text('Add Categories'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FormField<app_models.Category>(
      initialValue: _selectedCategory,
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
      builder: (FormFieldState<app_models.Category> state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Category',
            errorText: state.errorText,
            border: const OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<app_models.Category>(
              value: _selectedCategory,
              isDense: true,
              isExpanded: true,
              onChanged: (app_models.Category? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  state.didChange(newValue);
                });
              },
              items: _categories.map((app_models.Category category) {
                return DropdownMenuItem<app_models.Category>(
                  value: category,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.3), width: 1),
                        ),
                        child: Icon(category.icon,
                            color: category.color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      try {
        // Step 1: Create and save the recurring definition
        final expenditure = Expenditure(
          name: _nameController.text,
          category: _selectedCategory!.name,
          dateTime: _selectedDateTime,
          cost: double.parse(_costController.text),
          isRecurring: _isRecurring,
          repeatFrequency: _repeatFrequency,
          endOption: _endOption,
          endDate: _endOption == 'Custom' ? _endDate : null,
          notes: _notesController.text, // Include notes
        );

        // Save to database first and get the ID
        final id = await DatabaseHelper.instance.insertExpenditure(expenditure);
        debugPrint('Saved expenditure with ID: $id');

        // If it's recurring, ensure we also create the first instance
        if (_isRecurring && id > 0) {
          // Create a copy with the new ID
          final recurringExpense = expenditure.copyWith(id: id);

          // Create the first instance explicitly (not recurring, points to parent)
          final firstInstance = Expenditure(
            name: _nameController.text,
            category: _selectedCategory!.name,
            dateTime: _selectedDateTime, // Same date as definition
            cost: double.parse(_costController.text),
            isRecurring: false, // Instance, not definition
            parentRecurringId: id, // Points to parent
            notes: _notesController.text,
          );

          // Save the first instance
          final instanceId =
              await DatabaseHelper.instance.insertExpenditure(firstInstance);
          debugPrint('Saved first instance with ID: $instanceId');

          // Now process FUTURE instances (after the original date)
          await RecurringService.instance
              .processNewRecurringTransaction(recurringExpense);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  _isRecurring ? 'Recurring expense saved' : 'Expense saved'),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(
              context, true); // Return true to indicate data was saved
        }
      } catch (e) {
        debugPrint('Error saving expense: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving expense'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
}
