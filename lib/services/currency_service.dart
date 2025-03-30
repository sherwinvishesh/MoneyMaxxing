// lib/services/currency_service.dart
import 'package:flutter/material.dart';
import '../models/currency_settings.dart';
import '../services/database_helper.dart';

class CurrencyService {
  static final CurrencyService instance = CurrencyService._init();

  // Cache variables
  DateTime _lastRefreshTime = DateTime(1970); // Never refreshed initially
  CurrencySettings? _cachedCurrencySettings;

  // Cache timeout (5 seconds)
  static const Duration _cacheTimeout = Duration(seconds: 5);

  CurrencyService._init();

  // Force refresh currency settings
  Future<void> forceRefresh() async {
    _lastRefreshTime = DateTime(1970); // Reset refresh time to force refresh
    await getCurrencySettings(forceRefresh: true);
  }

  // Get the current currency settings
  Future<CurrencySettings> getCurrencySettings(
      {bool forceRefresh = false}) async {
    // Check if cache is valid and we're not forcing a refresh
    final now = DateTime.now();
    if (!forceRefresh &&
        now.difference(_lastRefreshTime) < _cacheTimeout &&
        _cachedCurrencySettings != null) {
      return _cachedCurrencySettings!;
    }

    try {
      final settings = await DatabaseHelper.instance.getCurrencySettings();

      // Update cache
      _cachedCurrencySettings = settings;
      _lastRefreshTime = now;

      return settings;
    } catch (e) {
      debugPrint('Error getting currency settings: $e');

      // Return default settings in case of error
      if (_cachedCurrencySettings != null) {
        return _cachedCurrencySettings!;
      }

      return CurrencySettings(
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
    }
  }

  // Save new currency settings
  Future<void> saveCurrencySettings(CurrencySettings settings) async {
    try {
      await DatabaseHelper.instance.saveCurrencySettings(settings);

      // Update cache
      _cachedCurrencySettings = settings;
      _lastRefreshTime = DateTime.now();
    } catch (e) {
      debugPrint('Error saving currency settings: $e');
      throw e;
    }
  }

  // Get currency symbol as a convenient shortcut
  Future<String> getCurrencySymbol() async {
    final settings = await getCurrencySettings();
    return settings.currencySymbol;
  }
}
