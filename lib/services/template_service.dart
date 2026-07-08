import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Available voucher template types
enum VoucherTemplate {
  full, // Full size with all details and cut lines
  compact, // Compact version, smaller QR, less spacing
  minimal, // Minimal design, just QR and credentials
  classic, // Classic style - price on left, horizontal layout
  modern, // Modern style - colorful, price badge
  compactAlt, // Alternative compact - list style
}

/// Service for managing voucher template preferences
class TemplateService {
  static const String _storageKey = 'voucher_template';
  static const String _customTemplateKey = 'custom_voucher_template';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<VoucherTemplate> loadTemplate() async {
    try {
      final savedTemplate = await _storage.read(key: _storageKey);
      if (savedTemplate != null) {
        final enumName = savedTemplate.contains('.')
            ? savedTemplate.split('.').last
            : savedTemplate;
        return VoucherTemplate.values.firstWhere(
          (e) => e.name == enumName,
          orElse: () => VoucherTemplate.full,
        );
      }
    } catch (e) {
      // Error loading template, use default
    }
    return VoucherTemplate.full;
  }

  static Future<void> saveTemplate(VoucherTemplate template) async {
    try {
      await _storage.write(key: _storageKey, value: template.name);
    } catch (e) {
      // Error saving template
    }
  }

  static Future<CustomVoucherTemplate?> loadCustomTemplate() async {
    try {
      final savedTemplate = await _storage.read(key: _customTemplateKey);
      if (savedTemplate != null) {
        final json = jsonDecode(savedTemplate) as Map<String, dynamic>;
        return CustomVoucherTemplate.fromJson(json);
      }
    } catch (e) {
      // Error loading custom template
    }
    return null;
  }

  static Future<void> saveCustomTemplate(CustomVoucherTemplate template) async {
    try {
      await _storage.write(key: _customTemplateKey, value: jsonEncode(template.toJson()));
    } catch (e) {
      // Error saving custom template
    }
  }

  static String getTemplateName(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return 'Full Size';
      case VoucherTemplate.compact:
        return 'Compact';
      case VoucherTemplate.minimal:
        return 'Minimal';
      case VoucherTemplate.classic:
        return 'Classic';
      case VoucherTemplate.modern:
        return 'Modern';
      case VoucherTemplate.compactAlt:
        return 'Compact Alt';
    }
  }

  static String getTemplateDescription(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return 'Complete voucher with all details and cut lines';
      case VoucherTemplate.compact:
        return 'Smaller voucher with essential info';
      case VoucherTemplate.minimal:
        return 'Simple design with QR and credentials only';
      case VoucherTemplate.classic:
        return 'Traditional layout with price on side (Style 1)';
      case VoucherTemplate.modern:
        return 'Colorful with price badge (Style 2)';
      case VoucherTemplate.compactAlt:
        return 'Small card with decorative background (Style 3)';
    }
  }

  static IconData getTemplateIcon(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return Icons.description_rounded;
      case VoucherTemplate.compact:
        return Icons.notes_rounded;
      case VoucherTemplate.minimal:
        return Icons.receipt_rounded;
      case VoucherTemplate.classic:
        return Icons.receipt_long_rounded;
      case VoucherTemplate.modern:
        return Icons.style_rounded;
      case VoucherTemplate.compactAlt:
        return Icons.view_list_rounded;
    }
  }

  static int getQrSize(VoucherTemplate template, {bool isBulk = false}) {
    switch (template) {
      case VoucherTemplate.full:
        return isBulk ? 150 : 300;
      case VoucherTemplate.compact:
        return isBulk ? 100 : 200;
      case VoucherTemplate.minimal:
        return isBulk ? 80 : 150;
      case VoucherTemplate.classic:
        return isBulk ? 60 : 100;
      case VoucherTemplate.modern:
        return isBulk ? 80 : 120;
      case VoucherTemplate.compactAlt:
        return isBulk ? 60 : 80;
    }
  }

  static String getCardMaxWidth(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return '400px';
      case VoucherTemplate.compact:
        return '300px';
      case VoucherTemplate.minimal:
        return '250px';
      case VoucherTemplate.classic:
        return '230px';
      case VoucherTemplate.modern:
        return '260px';
      case VoucherTemplate.compactAlt:
        return '200px';
    }
  }

  static String getCardPadding(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return '30px';
      case VoucherTemplate.compact:
        return '20px';
      case VoucherTemplate.minimal:
        return '15px';
      case VoucherTemplate.classic:
        return '12px';
      case VoucherTemplate.modern:
        return '15px';
      case VoucherTemplate.compactAlt:
        return '8px';
    }
  }

  static String getGridMinWidth(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return '350px';
      case VoucherTemplate.compact:
        return '250px';
      case VoucherTemplate.minimal:
        return '200px';
      case VoucherTemplate.classic:
        return '240px';
      case VoucherTemplate.modern:
        return '280px';
      case VoucherTemplate.compactAlt:
        return '190px';
    }
  }
}

class CustomVoucherTemplate {
  final String companyName;
  final String headerText;
  final bool showUsername;
  final bool showPassword;
  final bool showValidity;
  final bool showProfile;
  final bool showPrice;
  final bool showQrCode;
  final bool showCutLines;
  final String primaryColor;
  final String backgroundColor;

  const CustomVoucherTemplate({
    this.companyName = 'Hotspot WiFi',
    this.headerText = 'WiFi Voucher',
    this.showUsername = true,
    this.showPassword = true,
    this.showValidity = true,
    this.showProfile = true,
    this.showPrice = true,
    this.showQrCode = true,
    this.showCutLines = true,
    this.primaryColor = '#7C3AED',
    this.backgroundColor = '#1E293B',
  });

  CustomVoucherTemplate copyWith({
    String? companyName,
    String? headerText,
    bool? showUsername,
    bool? showPassword,
    bool? showValidity,
    bool? showProfile,
    bool? showPrice,
    bool? showQrCode,
    bool? showCutLines,
    String? primaryColor,
    String? backgroundColor,
  }) {
    return CustomVoucherTemplate(
      companyName: companyName ?? this.companyName,
      headerText: headerText ?? this.headerText,
      showUsername: showUsername ?? this.showUsername,
      showPassword: showPassword ?? this.showPassword,
      showValidity: showValidity ?? this.showValidity,
      showProfile: showProfile ?? this.showProfile,
      showPrice: showPrice ?? this.showPrice,
      showQrCode: showQrCode ?? this.showQrCode,
      showCutLines: showCutLines ?? this.showCutLines,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'headerText': headerText,
      'showUsername': showUsername,
      'showPassword': showPassword,
      'showValidity': showValidity,
      'showProfile': showProfile,
      'showPrice': showPrice,
      'showQrCode': showQrCode,
      'showCutLines': showCutLines,
      'primaryColor': primaryColor,
      'backgroundColor': backgroundColor,
    };
  }

  factory CustomVoucherTemplate.fromJson(Map<String, dynamic> json) {
    return CustomVoucherTemplate(
      companyName: json['companyName'] as String? ?? 'Hotspot WiFi',
      headerText: json['headerText'] as String? ?? 'WiFi Voucher',
      showUsername: json['showUsername'] as bool? ?? true,
      showPassword: json['showPassword'] as bool? ?? true,
      showValidity: json['showValidity'] as bool? ?? true,
      showProfile: json['showProfile'] as bool? ?? true,
      showPrice: json['showPrice'] as bool? ?? true,
      showQrCode: json['showQrCode'] as bool? ?? true,
      showCutLines: json['showCutLines'] as bool? ?? true,
      primaryColor: json['primaryColor'] as String? ?? '#7C3AED',
      backgroundColor: json['backgroundColor'] as String? ?? '#1E293B',
    );
  }
}
