// lib/models/financial_transaction.dart
import 'package:flutter/material.dart';
import 'expenditure.dart';
import 'income.dart';
import '../services/currency_service.dart';

// This is a wrapper class that can represent either an expenditure or income
class FinancialTransaction {
  final int? id;
  final String name;
  final DateTime dateTime;
  final double amount;
  final bool isIncome;
  final String? category; // Only applicable for expenditures
  final String? notes; // Added notes field

  const FinancialTransaction({
    this.id,
    required this.name,
    required this.dateTime,
    required this.amount,
    required this.isIncome,
    this.category,
    this.notes,
  });

  // Factory method to create a Transaction from an Expenditure
  factory FinancialTransaction.fromExpenditure(Expenditure expenditure) {
    return FinancialTransaction(
      id: expenditure.id,
      name: expenditure.name,
      dateTime: expenditure.dateTime,
      amount: expenditure.cost,
      isIncome: false,
      category: expenditure.category,
      notes: expenditure.notes, // Added notes from expenditure
    );
  }

  // Factory method to create a Transaction from an Income
  factory FinancialTransaction.fromIncome(Income income) {
    return FinancialTransaction(
      id: income.id,
      name: income.name,
      dateTime: income.dateTime,
      amount: income.amount,
      isIncome: true,
      category: null, // Income doesn't have a category
      notes: income.notes, // Added notes from income
    );
  }

  // Helper methods to get display text
  // String getAmountDisplay() {
  //   final prefix = isIncome ? '+' : '-';
  //   return '$prefix\$${amount.toStringAsFixed(2)}';
  // }
  Future<String> getAmountDisplay() async {
    final symbol = await CurrencyService.instance.getCurrencySymbol();
    final prefix = isIncome ? '+' : '-';
    return '$prefix$symbol${amount.toStringAsFixed(2)}';
  }

  Color getAmountColor() {
    return isIncome ? Colors.green : Colors.white;
  }
}
