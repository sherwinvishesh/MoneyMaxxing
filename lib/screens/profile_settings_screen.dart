// lib/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/profile_settings.dart';
import '../services/database_helper.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _customNameController = TextEditingController();

  bool _isLoading = true;
  String _displayNameOption = 'userName';
  bool _customNameVisible = false;

  @override
  void initState() {
    super.initState();
    _loadProfileSettings();
  }

  Future<void> _loadProfileSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getProfileSettings();

      if (mounted) {
        setState(() {
          _firstNameController.text = settings.firstName;
          _lastNameController.text = settings.lastName;
          _userNameController.text = settings.userName;
          _customNameController.text = settings.customName;
          _displayNameOption = settings.displayNameOption;
          _customNameVisible = settings.displayNameOption == 'custom';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfileSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final settings = ProfileSettings(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        userName: _userNameController.text,
        displayNameOption: _displayNameOption,
        customName: _customNameController.text,
      );

      await DatabaseHelper.instance.saveProfileSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile settings saved')),
        );
        Navigator.pop(
            context, true); // Return true to indicate data was changed
      }
    } catch (e) {
      debugPrint('Error saving profile settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving profile settings')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile Settings'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
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
                              'Personal Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'First Name',
                              controller: _firstNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Last Name',
                              controller: _lastNameController,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Username',
                              controller: _userNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
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
                              'Display Preferences',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Call me by:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _displayNameOption,
                                  dropdownColor: const Color(0xFF212121),
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.white),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _displayNameOption = newValue;
                                        _customNameVisible =
                                            newValue == 'custom';
                                      });
                                    }
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'firstName',
                                      child: Text(
                                          'First Name (${_firstNameController.text})'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'lastName',
                                      child: Text(
                                          'Last Name (${_lastNameController.text})'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'userName',
                                      child: Text(
                                          'Username (${_userNameController.text})'),
                                    ),
                                    const DropdownMenuItem<String>(
                                      value: 'custom',
                                      child: Text('Custom Name'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_customNameVisible) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Custom Name',
                                controller: _customNameController,
                                validator: (value) {
                                  if (_displayNameOption == 'custom' &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter a custom name';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfileSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Save Profile Settings',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userNameController.dispose();
    _customNameController.dispose();
    super.dispose();
  }
}
