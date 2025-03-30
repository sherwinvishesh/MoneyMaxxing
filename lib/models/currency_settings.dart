// lib/models/currency_settings.dart
class CurrencySettings {
  final int? id;
  final String currencyCode; // EUR, USD, CHF, etc.
  final String currencySymbol; // €, $, Fr, etc.

  CurrencySettings({
    this.id,
    required this.currencyCode,
    required this.currencySymbol,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };
  }

  static CurrencySettings fromMap(Map<String, dynamic> map) {
    return CurrencySettings(
      id: map['id'],
      currencyCode: map['currencyCode'],
      currencySymbol: map['currencySymbol'],
    );
  }

  // Create a copy with modified properties
  CurrencySettings copyWith({
    int? id,
    String? currencyCode,
    String? currencySymbol,
  }) {
    return CurrencySettings(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}

// Define available currencies
class AvailableCurrencies {
  static final List<CurrencySettings> currencies = [
    CurrencySettings(
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
    CurrencySettings(
      currencyCode: 'EUR',
      currencySymbol: '€',
    ),
    CurrencySettings(
      currencyCode: 'CHF',
      currencySymbol: 'Fr',
    ),
    // Add more currencies below:
    CurrencySettings(
      currencyCode: 'GBP',
      currencySymbol: '£',
    ),
    CurrencySettings(
      currencyCode: 'JPY',
      currencySymbol: '¥',
    ),
    CurrencySettings(
      currencyCode: 'INR',
      currencySymbol: '₹',
    ),
    CurrencySettings(
      currencyCode: 'CAD',
      currencySymbol: 'C\$',
    ),
    CurrencySettings(
      currencyCode: 'AUD',
      currencySymbol: 'A\$',
    ),
    CurrencySettings(
      currencyCode: 'SGD',
      currencySymbol: 'S\$',
    ),
    CurrencySettings(
      currencyCode: 'CNY',
      currencySymbol: '¥',
    ),
    CurrencySettings(
      currencyCode: 'MXN',
      currencySymbol: 'Mex\$',
    ),
    CurrencySettings(
      currencyCode: 'BRL',
      currencySymbol: 'R\$',
    ),
    CurrencySettings(
      currencyCode: 'ZAR',
      currencySymbol: 'R',
    ),
    // You can add more as needed
  ];

  // Helper to get a currency by code
  static CurrencySettings? getByCode(String code) {
    try {
      return currencies.firstWhere((c) => c.currencyCode == code);
    } catch (e) {
      return null;
    }
  }
}
