// lib/utils/color_themes.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryDark = Color(0xFF0098CC);
  
  // Background colors
  static const Color darkBg = Color(0xFF0F1419);
  static const Color darkCard = Color(0xFF1A1F2B);
  static const Color darkCardAlt = Color(0xFF252C3A);
  
  // Trading colors
  static const Color bullish = Color(0xFF00FF00);
  static const Color bullishLight = Color(0xFF4CAF50);
  static const Color bearish = Color(0xFFFF4444);
  static const Color bearishLight = Color(0xFFE53935);
  
  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);
  
  // Gradient colors
  static const LinearGradient bullishGradient = LinearGradient(
    colors: [bullish, bullishLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient bearishGradient = LinearGradient(
    colors: [bearish, bearishLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// lib/utils/number_formatter.dart
import 'package:intl/intl.dart';

class NumberFormatter {
  // Format price dengan 4-5 decimal places
  static String formatPrice(double price) {
    if (price.abs() < 0.0001) {
      return price.toStringAsFixed(6);
    }
    return price.toStringAsFixed(4);
  }

  // Format percentage
  static String formatPercentage(double value, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Format change dengan sign
  static String formatChange(double value, {int decimals = 2}) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}';
  }

  // Format large numbers
  static String formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  // Format currency
  static String formatCurrency(double value, String symbol = '\$') {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(value);
  }

  // Format confidence score
  static String formatConfidence(double confidence) {
    return '${confidence.toStringAsFixed(0)}%';
  }

  // Format RSI dengan color coding
  static String formatRSI(double rsi) {
    return rsi.toStringAsFixed(2);
  }
}

// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DateFormatter {
  // Format datetime dengan various styles
  static String formatDateTime(DateTime dateTime, {String format = 'dd/MM/yy HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }

  // Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  // Format date only
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  // Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
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

  // Format countdown
  static String formatCountdown(DateTime targetTime) {
    final now = DateTime.now();
    if (targetTime.isBefore(now)) {
      return 'Expired';
    }

    final difference = targetTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m ${difference.inSeconds % 60}s';
    }
  }

  // Format dengan timezone awareness
  static String formatWithTimezone(DateTime dateTime, String timezoneName) {
    try {
      final location = tz.getLocation(timezoneName);
      final zonedDateTime = tz.TZDateTime.from(dateTime, location);
      return DateFormat('dd/MM/yy HH:mm').format(zonedDateTime);
    } catch (e) {
      return formatDateTime(dateTime);
    }
  }

  // Get time until economic event
  static String getTimeUntilEvent(DateTime eventTime) {
    final now = DateTime.now();
    if (eventTime.isBefore(now)) {
      return 'Event passed';
    }

    final diff = eventTime.difference(now);
    if (diff.inMinutes < 1) {
      return 'In ${diff.inSeconds}s';
    }
    if (diff.inHours < 1) {
      return 'In ${diff.inMinutes}m';
    }
    if (diff.inDays < 1) {
      return 'In ${diff.inHours}h';
    }
    return 'In ${diff.inDays}d';
  }
}

// lib/utils/constants.dart
class AppConstants {
  // API Endpoints
  static const String baseURL = 'http://localhost:5000'; // Development
  // static const String baseURL = 'https://api.forexanalyzer.com'; // Production

  static const String quotesEndpoint = '/api/quotes';
  static const String candlesEndpoint = '/api/candles';
  static const String indicatorsEndpoint = '/api/indicators';
  static const String signalsEndpoint = '/api/signals';
  static const String sentimentEndpoint = '/api/sentiment';
  static const String newsEndpoint = '/api/news';
  static const String economicCalendarEndpoint = '/api/economic-calendar';

  // WebSocket
  static const String webSocketURL = 'ws://localhost:5000'; // Development
  // static const String webSocketURL = 'wss://api.forexanalyzer.com'; // Production

  // Refresh intervals (milliseconds)
  static const int quoteRefreshInterval = 5000; // 5 seconds
  static const int chartRefreshInterval = 10000; // 10 seconds
  static const int sentimentRefreshInterval = 3600000; // 1 hour
  static const int newsRefreshInterval = 1800000; // 30 minutes

  // Chart settings
  static const int defaultCandleCount = 100;
  static const int maxCandleCount = 500;
  static const List<String> availableTimeframes = [
    '1m',
    '5m',
    '15m',
    '30m',
    '1h',
    '4h',
    '1d',
    '1w',
  ];

  // Trading parameters
  static const double defaultRiskPercentage = 1.0;
  static const double maxRiskPercentage = 5.0;
  static const int minSignalConfidence = 60; // 0-100

  // Forex pairs
  static const List<String> majorPairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'USD/CHF',
    'AUD/USD',
  ];

  static const List<String> minorPairs = [
    'EUR/GBP',
    'EUR/JPY',
    'GBP/JPY',
    'USD/CAD',
    'NZD/USD',
  ];

  // Indicator settings
  static const int rsiPeriod = 14;
  static const int macdFastPeriod = 12;
  static const int macdSlowPeriod = 26;
  static const int macdSignalPeriod = 9;
  static const int bollingerBandPeriod = 20;
  static const double bollingerBandStdDev = 2.0;
  static const int smaPeriod20 = 20;
  static const int smaPeriod50 = 50;
  static const int smaPeriod200 = 200;

  // Signal confidence thresholds
  static const double minConfidenceForTrade = 60.0;
  static const double highConfidenceThreshold = 80.0;

  // Sentiment score ranges
  static const double veryBullish = 0.6;
  static const double bullish = 0.2;
  static const double neutral = -0.2;
  static const double bearish = -0.6;

  // App version
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Storage keys
  static const String watchlistKey = 'watchlist';
  static const String settingsKey = 'settings';
  static const String signalsHistoryKey = 'signals_history';
  static const String apiKeysKey = 'api_keys';
}

// lib/utils/validators.dart
class Validators {
  static String? validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return 'Please enter a positive number';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a price';
    }
    final price = double.tryParse(value);
    if (price == null || price < 0) {
      return 'Please enter a valid price';
    }
    return null;
  }

  static String? validateRiskRewardRatio(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a ratio';
    }
    final ratio = double.tryParse(value);
    if (ratio == null || ratio < 0.5) {
      return 'Minimum risk:reward ratio is 0.5:1';
    }
    return null;
  }

  static String? validateAPIKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'API key is required';
    }
    if (value.length < 20) {
      return 'API key is too short';
    }
    return null;
  }
}