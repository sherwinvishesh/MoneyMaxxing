// lib/screens/edit_transaction/edit_expenditure_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/expenditure.dart';
// import '../../models/category.dart';
import '../../services/database_helper.dart';
import '../../services/recurring_service.dart';
import '../../models/category.dart' as app_models; // Add alias

class EditExpenditurePage extends StatefulWidget {
  final Expenditure expenditure;
  final bool isRecurring;

  const EditExpenditurePage({
    super.key,
    required this.expenditure,
    this.isRecurring = false,
  });

  @override
  State<EditExpenditurePage> createState() => _EditExpenditurePageState();
}

class _EditExpenditurePageState extends State<EditExpenditurePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late DateTime _selectedDateTime;
  app_models.Category? _selectedCategory; // Update type

  late bool _isRecurring;
  late String _repeatFrequency;
  late String _endOption;
  DateTime? _endDate;
  late TextEditingController _notesController;

  bool _isLoadingCategories = true;
  List<app_models.Category> _categories = []; // Update type

  final List<String> _frequencies = ['Day', 'Week', 'Bi-weekly', 'Month'];
  final List<String> _endOptions = ['Forever', 'Custom'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.expenditure.name);
    _costController =
        TextEditingController(text: widget.expenditure.cost.toString());
    _selectedDateTime = widget.expenditure.dateTime;
    _isRecurring = widget.expenditure.isRecurring;
    _repeatFrequency = widget.expenditure.repeatFrequency;
    _endOption = widget.expenditure.endOption;
    _endDate = widget.expenditure.endDate;
    _notesController = TextEditingController(text: widget.expenditure.notes);

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      final categories = await DatabaseHelper.instance.getAllCategories();

      // Find the category that matches the expenditure's category name
      app_models.Category? matchingCategory;
      for (var category in categories) {
        if (category.name == widget.expenditure.category) {
          matchingCategory = category;
          break;
        }
      }

      setState(() {
        _categories = categories;
        _selectedCategory = matchingCategory ??
            (categories.isNotEmpty ? categories.first : null);
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _updateExpenditure() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final updatedExpenditure = Expenditure(
        id: widget.expenditure.id,
        name: _nameController.text,
        category: _selectedCategory!.name,
        dateTime: _selectedDateTime,
        cost: double.parse(_costController.text),
        isRecurring: _isRecurring,
        repeatFrequency: _repeatFrequency,
        endOption: _endOption,
        endDate: _endOption == 'Custom' ? _endDate : null,
        parentRecurringId: widget.expenditure.parentRecurringId,
        notes: _notesController.text,
      );

      // If this is a recurring parent definition
      if (updatedExpenditure.isRecurring &&
          updatedExpenditure.parentRecurringId == null) {
        // Update the recurring definition itself
        await DatabaseHelper.instance.updateExpenditure(updatedExpenditure);

        // Check for new future instances but don't touch past instances
        await RecurringService.instance.checkAndProcessRecurring();
      } else {
        // This is just a regular expense or a recurring instance
        await DatabaseHelper.instance.updateExpenditure(updatedExpenditure);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRecurring
                ? 'Recurring expense updated. Future occurrences will reflect changes.'
                : 'Expense updated successfully'),
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating expense')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
            widget.isRecurring ? 'Edit Recurring Expense' : 'Edit Expense'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Expense Name',
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

                    // Category dropdown with icons
                    _buildCategoryDropdown(),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Cost',
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a cost';
                        }
                        final number = double.tryParse(value);
                        if (number == null) {
                          return 'Please enter a valid number';
                        }
                        if (number <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text(
                        'Date & Time',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, y HH:mm').format(_selectedDateTime),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing:
                          const Icon(Icons.calendar_today, color: Colors.white),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateTime,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
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
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(_selectedDateTime),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedDateTime = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: 'Add details about this expense...',
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

                    // Only show recurring options for recurring expenses or when editing from recurring screen
                    if (widget.isRecurring || _isRecurring) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text(
                          'Recurring Expense',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'This expense will repeat automatically',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endDate != null
                                        ? DateFormat('MMM d, y')
                                            .format(_endDate!)
                                        : 'Select End Date',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const Icon(Icons.calendar_today,
                                      color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _updateExpenditure,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Save Changes',
            style: TextStyle(fontSize: 16),
          ),
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
            labelStyle: const TextStyle(color: Colors.grey),
            errorText: state.errorText,
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<app_models.Category>(
              value: _selectedCategory,
              isDense: true,
              isExpanded: true,
              dropdownColor: const Color(0xFF212121),
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
                      Text(
                        category.name,
                        style: const TextStyle(color: Colors.white),
                      ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
