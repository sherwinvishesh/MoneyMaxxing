// lib/screens/edit_expenditure/recurring_expenditure_edit_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expenditure.dart';
import '../../models/category.dart';
import '../../services/database_helper.dart';
import '../../services/recurring_service.dart';

class RecurringExpenditureEditPage extends StatefulWidget {
  final Expenditure expenditure;

  const RecurringExpenditureEditPage({
    super.key,
    required this.expenditure,
  });

  @override
  State<RecurringExpenditureEditPage> createState() =>
      _RecurringExpenditureEditPageState();
}

class _RecurringExpenditureEditPageState
    extends State<RecurringExpenditureEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late DateTime _selectedDateTime; // Keep for reference but don't allow editing
  Category? _selectedCategory;
  late bool _isRecurring;
  late String _repeatFrequency;
  late String _endOption;
  DateTime? _endDate;
  late TextEditingController _notesController;

  final List<String> _frequencies = ['Day', 'Week', 'Bi-weekly', 'Month'];
  final List<String> _endOptions = ['Forever', 'Custom'];

  bool _isLoadingCategories = true;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.expenditure.name);
    _costController =
        TextEditingController(text: widget.expenditure.cost.toString());
    _selectedDateTime = widget.expenditure.dateTime; // Only for reference
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
      Category? matchingCategory;
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

  // Update all instances including past ones
  Future<void> _updateAllInstances() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      // Create updated expenditure with new values but keeping original date/time
      final updatedExpenditure = Expenditure(
        id: widget.expenditure.id,
        name: _nameController.text,
        category: _selectedCategory!.name,
        dateTime: _selectedDateTime, // Keep original date/time
        cost: double.parse(_costController.text),
        isRecurring: _isRecurring,
        repeatFrequency: _repeatFrequency,
        endOption: _endOption,
        endDate: _endOption == 'Custom' ? _endDate : null,
        parentRecurringId: widget.expenditure.parentRecurringId,
        notes: _notesController.text,
      );

      // First update the recurring definition itself
      await DatabaseHelper.instance.updateExpenditure(updatedExpenditure);

      // Update previous instances
      await _updatePreviousInstances(updatedExpenditure);

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
          const SnackBar(content: Text('Error updating recurring expenditure')),
        );
      }
    }
  }

  // Update only future instances
  Future<void> _updateFutureInstancesOnly() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      // Create updated expenditure with new values but keeping original date/time
      final updatedExpenditure = Expenditure(
        id: widget.expenditure.id,
        name: _nameController.text,
        category: _selectedCategory!.name,
        dateTime: _selectedDateTime, // Keep original date/time
        cost: double.parse(_costController.text),
        isRecurring: _isRecurring,
        repeatFrequency: _repeatFrequency,
        endOption: _endOption,
        endDate: _endOption == 'Custom' ? _endDate : null,
        parentRecurringId: widget.expenditure.parentRecurringId,
        notes: _notesController.text,
      );

      // Update the recurring definition itself
      await DatabaseHelper.instance.updateExpenditure(updatedExpenditure);

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
          const SnackBar(content: Text('Error updating recurring expenditure')),
        );
      }
    }
  }

  Future<void> _updatePreviousInstances(Expenditure updatedExpenditure) async {
    // Make sure we have an ID
    if (updatedExpenditure.id == null) {
      debugPrint(
          'Cannot update instances for recurring expenditure without ID');
      return;
    }

    try {
      // Get all instances of this recurring expenditure
      final instances = await DatabaseHelper.instance
          .getRecurringExpenditureInstances(updatedExpenditure.id!);

      final db = await DatabaseHelper.instance.database;
      int updateCount = 0;

      // Update each instance with the new values
      for (final instance in instances) {
        // Update with new values but keep original date
        await db.update(
          'expenditures',
          {
            'name': updatedExpenditure.name,
            'category': updatedExpenditure.category,
            'cost': updatedExpenditure.cost,
            'notes': updatedExpenditure.notes,
            // Keep original dateTime, don't update it
          },
          where: 'id = ?',
          whereArgs: [instance.id],
        );

        updateCount++;
      }

      debugPrint('Updated $updateCount previous expenditure instances');
    } catch (e) {
      debugPrint('Error updating previous instances: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Recurring Expense'),
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
                    // Expense name field
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

                    // Category dropdown
                    _buildCategoryDropdown(),

                    const SizedBox(height: 16),

                    // Amount field
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a cost';
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
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
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
                        hintText: 'Add details about this recurring expense...',
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
                              const Icon(Icons.calendar_today,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

      // Two action buttons
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

    return FormField<Category>(
      initialValue: _selectedCategory,
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
      builder: (FormFieldState<Category> state) {
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
            child: DropdownButton<Category>(
              value: _selectedCategory,
              isDense: true,
              isExpanded: true,
              dropdownColor: const Color(0xFF212121),
              onChanged: (Category? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  state.didChange(newValue);
                });
              },
              items: _categories.map((Category category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, color: Colors.blue, size: 20),
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
