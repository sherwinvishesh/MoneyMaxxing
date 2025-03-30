// lib/screens/month_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/month_settings.dart';
import '../services/database_helper.dart';

class MonthSettingsScreen extends StatefulWidget {
  const MonthSettingsScreen({super.key});

  @override
  State<MonthSettingsScreen> createState() => _MonthSettingsScreenState();
}

class _MonthSettingsScreenState extends State<MonthSettingsScreen> {
  bool _isLoading = true;
  int _selectedStartDay = 1;
  int _originalStartDay = 1;

  @override
  void initState() {
    super.initState();
    _loadMonthSettings();
  }

  Future<void> _loadMonthSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getMonthSettings();

      if (mounted) {
        setState(() {
          _selectedStartDay = settings.startDay;
          _originalStartDay = settings.startDay;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading month settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveMonthSettings() async {
    try {
      final settings = MonthSettings(
        startDay: _selectedStartDay,
      );

      await DatabaseHelper.instance.saveMonthSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Month settings saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving month settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving month settings')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Month Settings'),
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
                            'Financial Month Start Date',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'The financial month starts every:',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedStartDay,
                                dropdownColor: const Color(0xFF212121),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.white),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedStartDay = newValue;
                                    });
                                  }
                                },
                                items: List.generate(28, (index) => index + 1)
                                    .map<DropdownMenuItem<int>>((int value) {
                                  // Add appropriate suffix (st, nd, rd, th)
                                  String suffix;
                                  if (value % 10 == 1 && value != 11) {
                                    suffix = 'st';
                                  } else if (value % 10 == 2 && value != 12) {
                                    suffix = 'nd';
                                  } else if (value % 10 == 3 && value != 13) {
                                    suffix = 'rd';
                                  } else {
                                    suffix = 'th';
                                  }

                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child:
                                        Text('$value$suffix day of each month'),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your financial month will run from day $_selectedStartDay of the current month to day ${_selectedStartDay - 1} of the next month.',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveMonthSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Save Month Settings',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
