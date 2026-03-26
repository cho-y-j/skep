import 'package:flutter/material.dart';

class ApiHelpers {
  /// Parse API response that may be List, Map with 'content', or Map with custom key
  static List<Map<String, dynamic>> parseList(dynamic data, {String? key}) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map) {
      if (key != null && data[key] is List) return (data[key] as List).cast<Map<String, dynamic>>();
      if (data['content'] is List) return (data['content'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Format date from dynamic (String, DateTime, null)
  static String formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  /// Format money with comma separator
  static String formatMoney(num amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
