// lib/models/month_settings.dart
class MonthSettings {
  final int? id;
  final int startDay;

  MonthSettings({
    this.id,
    required this.startDay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDay': startDay,
    };
  }

  static MonthSettings fromMap(Map<String, dynamic> map) {
    return MonthSettings(
      id: map['id'],
      startDay: map['startDay'],
    );
  }
}
