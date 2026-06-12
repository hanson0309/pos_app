import 'dart:math' show pow;

import 'package:intl/intl.dart';

class Helpers {
  // Format Currency
  static String formatCurrency(double amount, {String symbol = 'RM'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format Date
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    final formatter = DateFormat(format);
    return formatter.format(date);
  }

  // Format DateTime
  static String formatDateTime(DateTime dateTime, {String format = 'dd/MM/yyyy HH:mm'}) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  // Format Time
  static String formatTime(DateTime time, {String format = 'HH:mm'}) {
    final formatter = DateFormat(format);
    return formatter.format(time);
  }

  // Parse Date
  static DateTime? parseDate(String dateString, {String format = 'yyyy-MM-dd'}) {
    try {
      final formatter = DateFormat(format);
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Calculate Tax
  static double calculateTax(double amount, double taxRate) {
    return amount * (taxRate / 100);
  }

  // Calculate Total with Tax
  static double calculateTotalWithTax(double amount, double taxRate) {
    return amount + calculateTax(amount, taxRate);
  }

  /// Invoice prefix for current month (INV-YYYYMM-).
  static String invoiceDocumentPrefix([DateTime? when]) {
    final now = when ?? DateTime.now();
    final period =
        '${now.year}${now.month.toString().padLeft(2, '0')}';
    return 'INV-$period-';
  }

  /// Format full invoice number: INV-YYYYMM-0001
  static String formatInvoiceDocumentNumber(int sequence, [DateTime? when]) {
    if (sequence < 1 || sequence > 9999) {
      throw ArgumentError('sequence must be 1–9999');
    }
    return '${invoiceDocumentPrefix(when)}${sequence.toString().padLeft(4, '0')}';
  }

  // Validate Email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validate Phone
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  // Validate PIN
  static bool isValidPin(String pin) {
    final pinRegex = RegExp(r'^\d{4,6}$');
    return pinRegex.hasMatch(pin);
  }

  // Truncate String
  static String truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Get Initials
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Calculate Percentage
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  // Round to Decimal Places
  static double roundToDecimal(double value, int decimalPlaces) {
    final factor = pow(10, decimalPlaces).toDouble();
    return (value * factor).round() / factor;
  }

  // Check if Date is Today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if Date is Yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Get Relative Time
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }
}
