// lib/models/expenditure.dart
class Expenditure {
  final int? id;
  final String name;
  final String category;
  final DateTime dateTime;
  final double cost;
  final bool isRecurring;
  final String repeatFrequency;
  final String endOption;
  final DateTime? endDate;
  final int?
      parentRecurringId; // Reference to the original recurring transaction
  final String notes;

  Expenditure({
    this.id,
    required this.name,
    required this.category,
    required this.dateTime,
    required this.cost,
    this.isRecurring = false,
    this.repeatFrequency = 'Month',
    this.endOption = 'Forever',
    this.endDate,
    this.parentRecurringId,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    // Include recurring fields in the map
    return {
      'id': id,
      'name': name,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
      'cost': cost,
      'isRecurring': isRecurring ? 1 : 0,
      'repeatFrequency': repeatFrequency,
      'endOption': endOption,
      'endDate': endDate?.toIso8601String(),
      'parentRecurringId': parentRecurringId,
      'notes': notes,
    };
  }

  static Expenditure fromMap(Map<String, dynamic> map) {
    return Expenditure(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      dateTime: DateTime.parse(map['dateTime']),
      cost: map['cost'],
      isRecurring: map['isRecurring'] == 1,
      repeatFrequency: map['repeatFrequency'] ?? 'Month',
      endOption: map['endOption'] ?? 'Forever',
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      parentRecurringId: map['parentRecurringId'],
      notes: map['notes'] ?? '',
    );
  }

  // Create a copy with modified properties
  Expenditure copyWith({
    int? id,
    String? name,
    String? category,
    DateTime? dateTime,
    double? cost,
    bool? isRecurring,
    String? repeatFrequency,
    String? endOption,
    DateTime? endDate,
    int? parentRecurringId,
    String? notes,
  }) {
    return Expenditure(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      cost: cost ?? this.cost,
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
      final formatter =
          DateTime.now().year == endDate!.year ? 'MMM d' : 'MMM d, y';
      final endDateStr = endDate.toString().substring(0, 10);
      return '$frequency until $endDateStr';
    }

    return frequency;
  }
}
