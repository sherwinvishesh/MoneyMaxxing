// lib/models/budget_settings.dart
class BudgetSettings {
  final int? id;
  final double totalIncomeGoal;
  final double totalSavingsGoal;
  final String? monthYear; // Format: "YYYY-MM" to track month-specific settings

  BudgetSettings({
    this.id,
    required this.totalIncomeGoal,
    required this.totalSavingsGoal,
    this.monthYear,
  });

  double get totalBudgetGoal => totalIncomeGoal - totalSavingsGoal;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalIncomeGoal': totalIncomeGoal,
      'totalSavingsGoal': totalSavingsGoal,
      'monthYear': monthYear,
    };
  }

  static BudgetSettings fromMap(Map<String, dynamic> map) {
    return BudgetSettings(
      id: map['id'],
      totalIncomeGoal: map['totalIncomeGoal'],
      totalSavingsGoal: map['totalSavingsGoal'],
      monthYear: map['monthYear'],
    );
  }

  // Create a copy with modified properties
  BudgetSettings copyWith({
    int? id,
    double? totalIncomeGoal,
    double? totalSavingsGoal,
    String? monthYear,
  }) {
    return BudgetSettings(
      id: id ?? this.id,
      totalIncomeGoal: totalIncomeGoal ?? this.totalIncomeGoal,
      totalSavingsGoal: totalSavingsGoal ?? this.totalSavingsGoal,
      monthYear: monthYear ?? this.monthYear,
    );
  }
}
