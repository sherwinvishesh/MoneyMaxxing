// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'edit_transaction/all_transactions_edit_page.dart';
import 'recurring_transactions_screen.dart';
import 'main_navigation_screen.dart';
import 'budget_settings_screen.dart';
import 'recurring_income_screen.dart';
import 'month_settings_screen.dart';
import 'currency_settings_screen.dart';
import 'category_settings_screen.dart';

import 'profile_settings_screen.dart'; // Add this import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _refreshDashboard(BuildContext context) async {
    // Find main navigation screen
    final mainNavigation =
        context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNavigation != null) {
      // Get dashboard state using the key and refresh
      final dashboardState = mainNavigation.dashboardKey.currentState;
      if (dashboardState != null) {
        await dashboardState.refreshExpenditures();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          // Edit All Transactions
          ListTile(
            leading: const Icon(
              Icons.sync_alt,
              color: Colors.blue,
            ),
            title: const Text(
              'Edit Transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              final hasChanges = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllTransactionsEditPage(),
                ),
              );

              if (hasChanges == true) {
                await _refreshDashboard(context);
              }
            },
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),

          ListTile(
            leading: const Icon(
              Icons.repeat,
              color: Colors.blue,
            ),
            title: const Text(
              'Recurring Transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              final hasChanges = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecurringTransactionsScreen(),
                ),
              );

              if (hasChanges == true) {
                await _refreshDashboard(context);
              }
            },
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Manage',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),

          // Profile Settings (new option)
          ListTile(
            leading: const Icon(
              Icons.person,
              color: Colors.blue,
            ),
            title: const Text(
              'Profile Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              final hasChanges = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );

              // Refresh dashboard if profile was updated
              if (hasChanges == true) {
                await _refreshDashboard(context);
              }
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ),
          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),

          // Budget Settings
          ListTile(
            leading: const Icon(
              Icons.account_balance,
              color: Colors.blue,
            ),
            title: const Text(
              'Budget Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetSettingsScreen(),
                ),
              );
              // Refresh dashboard after returning from budget settings
              await _refreshDashboard(context);
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.category,
              color: Colors.blue,
            ),
            title: const Text(
              'Category Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              final hasChanges = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategorySettingsScreen(),
                ),
              );

              if (hasChanges == true) {
                // Refresh the dashboard if categories were changed
                await _refreshDashboard(context);
              }
            },
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),

          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),

          ListTile(
            leading: const Icon(
              Icons.calendar_month,
              color: Colors.blue,
            ),
            title: const Text(
              'Month Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MonthSettingsScreen(),
                ),
              );
              // You can add a refresh dashboard call here if needed
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ),
          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),

          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),

          // App Information Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'App Information',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.currency_exchange,
              color: Colors.blue,
            ),
            title: const Text(
              'Currency Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              final hasChanges = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencySettingsScreen(),
                ),
              );

              if (hasChanges == true) {
                await _refreshDashboard(context);
              }
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ),
          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: Colors.blue,
            ),
            title: const Text(
              'About MoneyMaxxing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF212121),
                  title: const Text('About MoneyMaxxing'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'MoneyMaxxing Finance is a personal finance management app designed to make savings addictive.'),
                      SizedBox(height: 16),
                      Text('Created with ❤️ by Sherwin Vishesh Jathanna'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.update,
              color: Colors.blue,
            ),
            title: const Text(
              'Version',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            trailing: const Text(
              '1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const Divider(
            color: Color(0xFF2C2C2E),
            thickness: 1,
          ),

          // Support Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Support',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.help_outline,
              color: Colors.blue,
            ),
            title: const Text(
              'Help & Feedback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () {
              // Show coming soon dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF212121),
                  title: const Text('Coming Soon'),
                  content: const Text(
                      'Help & Feedback section will be available in the next update.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: Colors.blue,
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () {
              // Show coming soon dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF212121),
                  title: const Text('Coming Soon'),
                  content: const Text(
                      'Privacy Policy will be available in the next update.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
