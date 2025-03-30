// In lib/services/category_service.dart

// Update the import
import 'package:flutter/material.dart';
import '../models/category.dart' as app_models;
import '../services/database_helper.dart';

class CategoryService {
  static final CategoryService instance = CategoryService._init();

  // Cache variables
  DateTime _lastRefreshTime = DateTime(1970); // Never refreshed initially
  List<app_models.Category> _cachedCategories = [];

  // Cache timeout (5 seconds)
  static const Duration _cacheTimeout = Duration(seconds: 5);

  CategoryService._init();

  // Force refresh categories
  Future<void> forceRefresh() async {
    _lastRefreshTime = DateTime(1970); // Reset refresh time to force refresh
    await getAllCategories(forceRefresh: true);
  }

  // Get all categories
  Future<List<app_models.Category>> getAllCategories(
      {bool forceRefresh = false}) async {
    // Check if cache is valid and we're not forcing a refresh
    final now = DateTime.now();
    if (!forceRefresh &&
        now.difference(_lastRefreshTime) < _cacheTimeout &&
        _cachedCategories.isNotEmpty) {
      return _cachedCategories;
    }

    try {
      final categories = await DatabaseHelper.instance.getAllCategories();

      // Update cache
      _cachedCategories = categories;
      _lastRefreshTime = now;

      return categories;
    } catch (e) {
      debugPrint('Error getting categories: $e');

      // Return cached categories in case of error
      if (_cachedCategories.isNotEmpty) {
        return _cachedCategories;
      }

      // If no cached categories available, create and return default ones
      return _createDefaultCategories();
    }
  }

  // Add a category
  Future<int> addCategory(app_models.Category category) async {
    try {
      final id = await DatabaseHelper.instance.insertCategory(category);

      // Reset cache
      _lastRefreshTime = DateTime(1970);

      return id;
    } catch (e) {
      debugPrint('Error adding category: $e');
      throw e;
    }
  }

  // Update a category
  Future<void> updateCategory(app_models.Category category) async {
    try {
      await DatabaseHelper.instance.updateCategory(category);

      // Reset cache
      _lastRefreshTime = DateTime(1970);
    } catch (e) {
      debugPrint('Error updating category: $e');
      throw e;
    }
  }

  // Delete a category
  Future<void> deleteCategory(int id) async {
    try {
      await DatabaseHelper.instance.deleteCategory(id);

      // Reset cache
      _lastRefreshTime = DateTime(1970);
    } catch (e) {
      debugPrint('Error deleting category: $e');
      throw e;
    }
  }

  // Create default categories if none exist
  Future<List<app_models.Category>> _createDefaultCategories() async {
    try {
      final defaultCategories = [
        app_models.Category(name: 'Housing', icon: Icons.home),
        app_models.Category(name: 'Transportation', icon: Icons.directions_car),
        app_models.Category(name: 'Food & Groceries', icon: Icons.restaurant),
        app_models.Category(name: 'Utilities & Bills', icon: Icons.receipt),
        app_models.Category(name: 'Healthcare', icon: Icons.medical_services),
        app_models.Category(name: 'Entertainment', icon: Icons.movie),
        app_models.Category(name: 'Personal', icon: Icons.person),
      ];

      // Save each default category to database
      for (final category in defaultCategories) {
        await DatabaseHelper.instance.insertCategory(category);
      }

      return defaultCategories;
    } catch (e) {
      debugPrint('Error creating default categories: $e');

      // Return in-memory defaults as fallback
      return [
        app_models.Category(name: 'Housing', icon: Icons.home),
        app_models.Category(name: 'Transportation', icon: Icons.directions_car),
        app_models.Category(name: 'Food & Groceries', icon: Icons.restaurant),
        app_models.Category(name: 'Utilities & Bills', icon: Icons.receipt),
        app_models.Category(name: 'Healthcare', icon: Icons.medical_services),
        app_models.Category(name: 'Entertainment', icon: Icons.movie),
        app_models.Category(name: 'Personal', icon: Icons.person),
      ];
    }
  }
}
