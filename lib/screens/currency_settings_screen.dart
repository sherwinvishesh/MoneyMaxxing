// lib/screens/currency_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/currency_settings.dart';
import '../services/currency_service.dart';
import 'main_navigation_screen.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  bool _isLoading = true;
  String _selectedCurrencyCode = 'USD';
  CurrencySettings? _currentSettings;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final settings = await CurrencyService.instance
          .getCurrencySettings(forceRefresh: true);

      if (mounted) {
        setState(() {
          _currentSettings = settings;
          _selectedCurrencyCode = settings.currencyCode;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading currency settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedCurrencyCode = 'USD'; // Default fallback
        });
      }
    }
  }

  Future<void> _saveCurrencySettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the selected currency details
      final selectedCurrency =
          AvailableCurrencies.getByCode(_selectedCurrencyCode);

      if (selectedCurrency != null) {
        // Save the new settings
        await CurrencyService.instance.saveCurrencySettings(selectedCurrency);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Currency changed to ${selectedCurrency.currencyCode}')));

          // Refresh the main app
          _refreshApp();

          // Navigate back
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Invalid currency selected');
      }
    } catch (e) {
      debugPrint('Error saving currency settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error changing currency')));
      }
    }
  }

  void _refreshApp() {
    // Find main navigation screen
    final mainNavigation =
        context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNavigation != null) {
      // Get dashboard state using the key and refresh
      final dashboardState = mainNavigation.getDashboardKey.currentState;
      if (dashboardState != null) {
        dashboardState.refreshExpenditures();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Currency Settings'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: const Color(0xFF212121),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Currency Selection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Select your preferred currency:',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Currency selection radio buttons
                          ...AvailableCurrencies.currencies.map((currency) {
                            return RadioListTile<String>(
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      currency.currencySymbol,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    currency.currencyCode,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              value: currency.currencyCode,
                              groupValue: _selectedCurrencyCode,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrencyCode = value!;
                                });
                              },
                              activeColor: Colors.blue,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFF212121),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Currency:',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _currentSettings?.currencyCode ?? 'USD',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _currentSettings?.currencySymbol ?? '\$',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveCurrencySettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Save Currency Settings',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Card(
                    color: Color(0xFF212121),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 10),
                              Text(
                                'Important Note',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Changing the currency will affect how all monetary values are displayed throughout the app. This will not convert your existing values - it will only change the currency symbol used.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
