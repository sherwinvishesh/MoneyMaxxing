// lib/screens/category_settings_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/category.dart' as app_models;

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  List<app_models.Category> _categories = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  // Available icons for selection when adding/editing a category
  final List<IconData> _availableIcons = [
    // Home & Living
    Icons.home,
    Icons.house,
    Icons.apartment,
    Icons.holiday_village,
    Icons.villa,
    Icons.cleaning_services,
    Icons.chair,
    Icons.bed,

    // Transportation
    Icons.directions_car,
    Icons.commute,
    Icons.directions_bus,
    Icons.train,
    Icons.flight,
    Icons.pedal_bike,
    Icons.electric_car,
    Icons.local_gas_station,

    // Food & Dining
    Icons.restaurant,
    Icons.fastfood,
    Icons.lunch_dining,
    Icons.local_pizza,
    Icons.coffee,
    Icons.local_bar,
    Icons.local_cafe,
    Icons.liquor,
    Icons.icecream,

    // Health & Wellness
    Icons.medical_services,
    Icons.local_hospital,
    Icons.medication,
    Icons.health_and_safety,
    Icons.healing,
    Icons.fitness_center,
    Icons.spa,

    // Entertainment & Leisure
    Icons.movie,
    Icons.theaters,
    Icons.sports_esports,
    Icons.sports,
    Icons.sports_basketball,
    Icons.casino,
    Icons.shopping_bag,
    Icons.beach_access,
    Icons.nightlife,

    // Education & Work
    Icons.school,
    Icons.work,
    Icons.book,
    Icons.science,
    Icons.laptop,
    Icons.engineering,
    Icons.business_center,

    // Utilities & Bills
    Icons.receipt,
    Icons.attach_money,
    Icons.account_balance,
    Icons.payments,
    Icons.phone,
    Icons.water_drop,
    Icons.bolt,
    Icons.wifi,

    // Personal & Misc
    Icons.person,
    Icons.face,
    Icons.child_care,
    Icons.pets,
    Icons.shopping_cart,
    Icons.card_giftcard,
    Icons.devices,
    Icons.public,
    Icons.watch,
    Icons.mail,
    Icons.camera_alt,
    Icons.favorite,
    Icons.celebration,
    Icons.construction,
  ];

  // Define expanded color palette with 18 colors (including white as first color)
  final List<Color> _colorPalette = [
    Colors.white, // White (first color)
    const Color(0xFF080156), // Federal Blue
    const Color(0xFFFF818E), // Light Red
    const Color(0xFFFE2464), // Folly
    const Color(0xFF7116BD), // Grape
    const Color(0xFF1BFF92), // Cyber Lime
    const Color(0xFF9B51E0), // Electric Lavender
    const Color(0xFF0FF0FC), // Glacial Tech Blue
    const Color(0xFF411FCA), // Chrysler Blue
    const Color(0xFF5F00BA), // Deep Violet
    const Color(0xFFBC13FE), // Ultra Purple
    // Adding 10 more colors
    Colors.red, // Red
    Colors.orange, // Orange
    Colors.amber, // Amber
    Colors.yellow, // Yellow
    Colors.lime, // Lime
    Colors.teal, // Teal
    Colors.indigo, // Indigo
    Colors.purple, // Purple
    Colors.pink, // Pink
    Colors.brown, // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await DatabaseHelper.instance.getAllCategories();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCategory(String name, IconData icon, Color color) async {
    try {
      // Check if we already have 10 categories
      if (_categories.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum of 10 categories allowed')),
        );
        return;
      }

      final category =
          app_models.Category(name: name, icon: icon, color: color);
      await DatabaseHelper.instance.insertCategory(category);
      _hasChanges = true;
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error adding category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding category: $e')),
        );
      }
    }
  }

  Future<void> _updateCategory(app_models.Category category, String name,
      IconData icon, Color color) async {
    try {
      final updatedCategory =
          category.copyWith(name: name, icon: icon, color: color);
      await DatabaseHelper.instance.updateCategory(updatedCategory);
      _hasChanges = true;
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating category: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(app_models.Category category) async {
    if (category.id == null) return;

    try {
      await DatabaseHelper.instance.deleteCategory(category.id!);
      _hasChanges = true;
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: ${e.toString()}')),
        );
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
          title: const Text('Category Settings'),
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
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Header card
                        Card(
                          color: const Color(0xFF212121),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expense Categories',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Customize your expense categories below. You can edit existing ones or add new categories (maximum 10).',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_categories.length} of 10 categories',
                                  style: TextStyle(
                                    color: _categories.length >= 10
                                        ? Colors.red
                                        : Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category list card
                        Card(
                          color: const Color(0xFF212121),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Categories',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // List of current categories
                                if (_categories.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        'No categories yet. Add one to get started.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ..._categories.map((category) =>
                                      _buildCategoryTile(category)),

                                // Add new category button - only show if we have fewer than 10 categories
                                if (_categories.length < 10)
                                  InkWell(
                                    onTap: () {
                                      _showAddCategoryDialog();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.blue.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Text(
                                            'Add new category',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Build a tile for each category
  Widget _buildCategoryTile(app_models.Category category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black, // Black background for icons
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: Icon(
              category.icon,
              color: category.color, // Use the category color
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () {
              _showEditCategoryDialog(category);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () {
              _showDeleteCategoryDialog(category);
            },
          ),
        ],
      ),
    );
  }

  // Show dialog to add a new category
  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    IconData selectedIcon = _availableIcons[0]; // Default to first icon
    Color selectedColor = _colorPalette[0]; // Default to first color (white)

    Widget dialogContent = StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select an Icon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            // Icon selection
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableIcons.map((IconData icon) {
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black, // Always black background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? selectedColor : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            // Use the selected color for all icons, or white if no color selected
                            color: selectedColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Add color selection
            const SizedBox(height: 20),
            const Text(
              'Select a Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _colorPalette.map((Color color) {
                    final isSelected = color.value == selectedColor.value;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF212121),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add New Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: dialogContent,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          _addCategory(nameController.text.trim(), selectedIcon,
                              selectedColor);
                          Navigator.pop(dialogContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show dialog to edit an existing category
  void _showEditCategoryDialog(app_models.Category category) {
    final TextEditingController nameController =
        TextEditingController(text: category.name);
    IconData selectedIcon = category.icon;
    Color selectedColor = category.color;

    Widget dialogContent = StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select an Icon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            // Use a fixed height container with Wrap instead of GridView
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableIcons.map((IconData icon) {
                      final isSelected =
                          icon.codePoint == selectedIcon.codePoint;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black, // Black background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? selectedColor : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            // Use the selected color for all icons
                            color: selectedColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Add color selection
            const SizedBox(height: 20),
            const Text(
              'Select a Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _colorPalette.map((Color color) {
                    final isSelected = color.value == selectedColor.value;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF212121),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: dialogContent,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          _updateCategory(category, nameController.text.trim(),
                              selectedIcon, selectedColor);
                          Navigator.pop(dialogContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show dialog to confirm category deletion
  void _showDeleteCategoryDialog(app_models.Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Delete Category'),
          content: Text(
            'Are you sure you want to delete the "${category.name}" category?\n\n'
            'If this category is being used by any expenses, you cannot delete it.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCategory(category);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
