import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;
  final String localeCode;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
    required this.localeCode,
  });
}

class CurrencyData {
  static const Map<String, CurrencyInfo> currencies = {
    'USD': CurrencyInfo(
        code: 'USD',
        symbol: '\$',
        name: 'US Dollar',
        decimalDigits: 2,
        localeCode: 'en_US'),
    'IDR': CurrencyInfo(
        code: 'IDR',
        symbol: 'Rp',
        name: 'Indonesian Rupiah',
        decimalDigits: 0,
        localeCode: 'id_ID'),
    'MYR': CurrencyInfo(
        code: 'MYR',
        symbol: 'RM',
        name: 'Malaysian Ringgit',
        decimalDigits: 2,
        localeCode: 'ms_MY'),
    'SGD': CurrencyInfo(
        code: 'SGD',
        symbol: 'S\$',
        name: 'Singapore Dollar',
        decimalDigits: 2,
        localeCode: 'en_SG'),
    'THB': CurrencyInfo(
        code: 'THB',
        symbol: '฿',
        name: 'Thai Baht',
        decimalDigits: 2,
        localeCode: 'th_TH'),
    'PHP': CurrencyInfo(
        code: 'PHP',
        symbol: '₱',
        name: 'Philippine Peso',
        decimalDigits: 2,
        localeCode: 'en_PH'),
    'VND': CurrencyInfo(
        code: 'VND',
        symbol: '₫',
        name: 'Vietnamese Dong',
        decimalDigits: 0,
        localeCode: 'vi_VN'),
    'EUR': CurrencyInfo(
        code: 'EUR',
        symbol: '€',
        name: 'Euro',
        decimalDigits: 2,
        localeCode: 'de_DE'),
    'GBP': CurrencyInfo(
        code: 'GBP',
        symbol: '£',
        name: 'British Pound',
        decimalDigits: 2,
        localeCode: 'en_GB'),
    'JPY': CurrencyInfo(
        code: 'JPY',
        symbol: '¥',
        name: 'Japanese Yen',
        decimalDigits: 0,
        localeCode: 'ja_JP'),
    'CNY': CurrencyInfo(
        code: 'CNY',
        symbol: '¥',
        name: 'Chinese Yuan',
        decimalDigits: 2,
        localeCode: 'zh_CN'),
    'INR': CurrencyInfo(
        code: 'INR',
        symbol: '₹',
        name: 'Indian Rupee',
        decimalDigits: 2,
        localeCode: 'en_IN'),
    'AUD': CurrencyInfo(
        code: 'AUD',
        symbol: 'A\$',
        name: 'Australian Dollar',
        decimalDigits: 2,
        localeCode: 'en_AU'),
    'NZD': CurrencyInfo(
        code: 'NZD',
        symbol: 'NZ\$',
        name: 'New Zealand Dollar',
        decimalDigits: 2,
        localeCode: 'en_NZ'),
  };

  static CurrencyInfo getCurrencyForLocale(String languageCode,
      {String? countryCode}) {
    switch (languageCode) {
      case 'id':
        return currencies['IDR']!;
      case 'ms':
        return currencies['MYR']!;
      case 'th':
        return currencies['THB']!;
      case 'vi':
        return currencies['VND']!;
      case 'tl':
      case 'ph':
        return currencies['PHP']!;
      case 'ja':
        return currencies['JPY']!;
      case 'zh':
        return currencies['CNY']!;
      case 'hi':
        return currencies['INR']!;
      case 'de':
        return currencies['EUR']!;
      case 'fr':
      case 'es':
      case 'it':
      case 'nl':
      case 'pt':
        return currencies['EUR']!;
      case 'en':
        if (countryCode == 'US') return currencies['USD']!;
        if (countryCode == 'SG') return currencies['SGD']!;
        if (countryCode == 'AU') return currencies['AUD']!;
        if (countryCode == 'NZ') return currencies['NZD']!;
        if (countryCode == 'GB') return currencies['GBP']!;
        if (countryCode == 'IN') return currencies['INR']!;
        return currencies['USD']!;
      default:
        return currencies['USD']!;
    }
  }

  static CurrencyInfo fromCode(String code) {
    return currencies[code] ?? currencies['USD']!;
  }

  static List<CurrencyInfo> get allCurrencies =>
      currencies.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

class CurrencyFormatter {
  static String format(double amount, CurrencyInfo currency) {
    final formatter = NumberFormat.currency(
      locale: currency.localeCode,
      symbol: currency.symbol,
      decimalDigits: currency.decimalDigits,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount, CurrencyInfo currency) {
    if (currency.code == 'IDR' ||
        currency.code == 'VND' ||
        currency.code == 'JPY') {
      if (amount >= 1000000) {
        return '${currency.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
      } else if (amount >= 1000) {
        return '${currency.symbol}${(amount / 1000).toStringAsFixed(0)}K';
      }
    }

    final formatter = NumberFormat.compactCurrency(
      locale: currency.localeCode,
      symbol: currency.symbol,
      decimalDigits: currency.decimalDigits,
    );
    return formatter.format(amount);
  }

  static String formatInput(double amount, CurrencyInfo currency) {
    final formatter = NumberFormat.decimalPattern(currency.localeCode);
    return formatter.format(amount);
  }
}
