// lib/models/income.dart
class Income {
  final int? id;
  final String name;
  final DateTime dateTime;
  final double amount;
  final bool isRecurring;
  final String repeatFrequency;
  final String endOption;
  final DateTime? endDate;
  final int? parentRecurringId; // This is needed for recurring instances
  final String notes;

  Income({
    this.id,
    required this.name,
    required this.dateTime,
    required this.amount,
    this.isRecurring = false,
    this.repeatFrequency = 'Month',
    this.endOption = 'Forever',
    this.endDate,
    this.parentRecurringId,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    // Include all fields for recurring functionality
    return {
      'id': id,
      'name': name,
      'dateTime': dateTime.toIso8601String(),
      'amount': amount,
      'isRecurring': isRecurring ? 1 : 0,
      'repeatFrequency': repeatFrequency,
      'endOption': endOption,
      'endDate': endDate?.toIso8601String(),
      'parentRecurringId': parentRecurringId,
      'notes': notes,
    };
  }

  static Income fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      name: map['name'],
      dateTime: DateTime.parse(map['dateTime']),
      amount: map['amount'],
      isRecurring: map['isRecurring'] == 1,
      repeatFrequency: map['repeatFrequency'] ?? 'Month',
      endOption: map['endOption'] ?? 'Forever',
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      parentRecurringId: map['parentRecurringId'],
      notes: map['notes'] ?? '',
    );
  }

  // Create a copy with modified properties
  Income copyWith({
    int? id,
    String? name,
    DateTime? dateTime,
    double? amount,
    bool? isRecurring,
    String? repeatFrequency,
    String? endOption,
    DateTime? endDate,
    int? parentRecurringId,
    String? notes,
  }) {
    return Income(
      id: id ?? this.id,
      name: name ?? this.name,
      dateTime: dateTime ?? this.dateTime,
      amount: amount ?? this.amount,
      isRecurring: isRecurring ?? this.isRecurring,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      endOption: endOption ?? this.endOption,
      endDate: endDate ?? this.endDate,
      parentRecurringId: parentRecurringId ?? this.parentRecurringId,
      notes: notes ?? this.notes,
    );
  }

  // Human-readable description of the recurrence pattern
  String getRecurrenceDescription() {
    if (!isRecurring) return 'One-time';

    String frequency = 'Every ';
    switch (repeatFrequency) {
      case 'Day':
        frequency += 'day';
        break;
      case 'Week':
        frequency += 'week';
        break;
      case 'Bi-weekly':
        frequency += 'two weeks';
        break;
      case 'Month':
        frequency += 'month';
        break;
      default:
        frequency += repeatFrequency.toLowerCase();
    }

    if (endOption == 'Forever') {
      return '$frequency (ongoing)';
    } else if (endOption == 'Custom' && endDate != null) {
      final endDateStr = endDate.toString().substring(0, 10);
      return '$frequency until $endDateStr';
    }

    return frequency;
  }
}
