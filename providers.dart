// lib/providers/forex_provider.dart
import 'package:flutter/material.dart';
import '../models/forex_pair.dart';
import '../models/candle.dart';
import '../services/api/broker_api.dart';
import '../services/api/websocket_service.dart';

class ForexProvider extends ChangeNotifier {
  final BrokerAPI brokerAPI = BrokerAPI(
    brokerType: BrokerType.mockData,
    apiKey: 'your_api_key',
    accountNumber: '123456',
  );

  Map<String, ForexPair> quotes = {};
  Map<String, List<Candle>> candles = {};
  bool isLoading = false;
  String? error;

  final List<String> pairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'USD/CHF',
    'AUD/USD',
  ];

  /// Initialize real-time updates
  Future<void> startRealTimeUpdates() async {
    isLoading = true;
    notifyListeners();

    try {
      // Get initial quotes
      for (String pair in pairs) {
        await getQuote(pair);
        await getCandles(pair, '1h');
      }

      // Start periodic updates
      _startPeriodicUpdates();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  /// Get quote untuk specific pair
  Future<void> getQuote(String pair) async {
    try {
      final quote = await brokerAPI.getQuote(pair);
      if (quote != null) {
        quotes[pair] = quote;
        notifyListeners();
      }
    } catch (e) {
      error = 'Error fetching quote: $e';
    }
  }

  /// Get candles untuk technical analysis
  Future<void> getCandles(
    String pair,
    String timeframe, {
    int count = 100,
  }) async {
    try {
      final candleData = await brokerAPI.getCandles(
        pair: pair,
        timeframe: timeframe,
        count: count,
      );

      if (candleData != null) {
        candles[pair] = candleData;
        notifyListeners();
      }
    } catch (e) {
      error = 'Error fetching candles: $e';
    }
  }

  /// Periodic update setiap 5 detik
  void _startPeriodicUpdates() {
    Future.delayed(const Duration(seconds: 5), () async {
      for (String pair in pairs) {
        await getQuote(pair);
      }
      _startPeriodicUpdates();
    });
  }

  /// Get available pairs
  Future<List<ForexPair>> getAvailablePairs() async {
    try {
      return await brokerAPI.getAvailablePairs();
    } catch (e) {
      error = 'Error fetching pairs: $e';
      return [];
    }
  }

  /// Pause real-time updates
  void pauseUpdates() {
    // Implementation untuk pause updates
  }

  /// Resume real-time updates
  void resumeUpdates() {
    // Implementation untuk resume updates
  }
}

// lib/providers/signals_provider.dart
import 'package:flutter/material.dart';
import '../models/signal.dart';
import '../models/candle.dart';
import '../models/indicator_values.dart';
import '../services/indicators/technical_indicators.dart';
import '../services/indicators/signal_generator.dart';

class SignalsProvider extends ChangeNotifier {
  List<Signal> signals = [];
  List<Signal> signalHistory = [];
  bool isGenerating = false;

  /// Generate signals untuk semua pairs
  Future<void> generateSignals() async {
    isGenerating = true;
    notifyListeners();

    try {
      // Contoh generate signal (dalam implementasi real, ambil data dari broker)
      // Placeholder signals untuk demo
      signals.clear();

      // In real implementation:
      // 1. Get candles dari broker API
      // 2. Calculate indicators menggunakan TechnicalIndicators
      // 3. Generate signals menggunakan SignalGenerator
      // 4. Add ke signals list

      _generatePlaceholderSignals();
    } catch (e) {
      print('Error generating signals: $e');
    }

    isGenerating = false;
    notifyListeners();
  }

  /// Generate signal untuk specific pair
  Future<void> generateSignalForPair({
    required String pair,
    required List<Candle> candles,
  }) async {
    try {
      if (candles.isEmpty) return;

      // Get close prices untuk calculation
      List<double> closePrices = candles.map((c) => c.close).toList();
      double currentPrice = candles.last.close;

      // Calculate indicators
      double rsi = TechnicalIndicators.calculateRSI(
        prices: closePrices,
        period: 14,
      );

      Map<String, double> macdData = TechnicalIndicators.calculateMACD(
        prices: closePrices,
      );

      Map<String, double> bbData = TechnicalIndicators.calculateBollingerBands(
        prices: closePrices,
      );

      // Create indicator values object
      IndicatorValues indicators = IndicatorValues(
        rsi: rsi,
        macdLine: macdData['macdLine'] ?? 0,
        macdSignal: macdData['signalLine'] ?? 0,
        macdHistogram: macdData['histogram'] ?? 0,
        bb_upper: bbData['upper'] ?? 0,
        bb_middle: bbData['middle'] ?? 0,
        bb_lower: bbData['lower'] ?? 0,
        sma20: TechnicalIndicators.calculateSMA(closePrices, 20),
        sma50: TechnicalIndicators.calculateSMA(closePrices, 50),
        sma200: TechnicalIndicators.calculateSMA(closePrices, 200),
        timestamp: DateTime.now(),
      );

      // Generate signal
      Signal? signal = SignalGenerator.generateSignal(
        pair: pair,
        candles: candles,
        indicators: indicators,
        currentPrice: currentPrice,
      );

      if (signal != null) {
        signals.add(signal);
        signalHistory.add(signal);
        notifyListeners();
      }
    } catch (e) {
      print('Error generating signal for $pair: $e');
    }
  }

  /// Get signals untuk specific pair
  List<Signal> getSignalsForPair(String pair) {
    return signals.where((s) => s.pair == pair).toList();
  }

  /// Clear old signals (keep last 100)
  void cleanupOldSignals() {
    if (signalHistory.length > 100) {
      signalHistory = signalHistory.sublist(signalHistory.length - 100);
      notifyListeners();
    }
  }

  /// Placeholder untuk demo
  void _generatePlaceholderSignals() {
    signals = [
      Signal(
        type: SignalType.strongBuy,
        source: SignalSource.combination,
        pair: 'EUR/USD',
        price: 1.1050,
        timestamp: DateTime.now(),
        confidence: 85,
        description: 'RSI oversold + MACD bullish crossover',
        indicators: ['RSI', 'MACD', 'MA'],
        strength: 3,
        takeProfitLevel: 1.1100,
        stopLossLevel: 1.0990,
      ),
      Signal(
        type: SignalType.sell,
        source: SignalSource.macd,
        pair: 'GBP/USD',
        price: 1.2700,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        confidence: 65,
        description: 'MACD death cross - bearish signal',
        indicators: ['MACD'],
        strength: 1,
      ),
    ];
  }
}

// lib/providers/sentiment_provider.dart
import 'package:flutter/material.dart';
import '../models/sentiment.dart';
import '../services/api/news_api.dart';

class SentimentProvider extends ChangeNotifier {
  final NewsAPI newsAPI = NewsAPI(
    source: NewsSource.finnhub,
    apiKey: 'your_finnhub_api_key',
  );

  Map<String, Sentiment> sentiments = {};
  Map<String, List<Map<String, dynamic>>> news = {};
  bool isAnalyzing = false;

  /// Analyze sentiment untuk specific pair
  Future<void> analyzeSentiment(String pair) async {
    isAnalyzing = true;
    notifyListeners();

    try {
      // Get news
      List<Map<String, dynamic>> newsItems = await newsAPI.getNews(
        pair: pair,
        limit: 20,
      );

      news[pair] = newsItems;

      // Analyze sentiment
      Sentiment? sentiment = await newsAPI.analyzeSentiment(
        pair: pair,
        newsItems: newsItems,
      );

      if (sentiment != null) {
        sentiments[pair] = sentiment;
        notifyListeners();
      }
    } catch (e) {
      print('Error analyzing sentiment: $e');
    }

    isAnalyzing = false;
    notifyListeners();
  }

  /// Get sentiment score (0-100)
  Future<double> getMarketSentimentScore(String pair) async {
    try {
      return await newsAPI.getMarketSentimentScore(pair);
    } catch (e) {
      print('Error getting sentiment score: $e');
      return 50; // Neutral
    }
  }

  /// Get news untuk specific pair
  List<Map<String, dynamic>> getNewsForPair(String pair) {
    return news[pair] ?? [];
  }

  /// Analyze sentiment untuk multiple pairs
  Future<void> analyzeMultiplePairsSentiment(List<String> pairs) async {
    for (String pair in pairs) {
      await analyzeSentiment(pair);
    }
  }
}

// lib/providers/economic_provider.dart
import 'package:flutter/material.dart';
import '../models/economic_event.dart';
import '../services/api/news_api.dart';

class EconomicProvider extends ChangeNotifier {
  final NewsAPI newsAPI = NewsAPI(
    source: NewsSource.finnhub,
    apiKey: 'your_finnhub_api_key',
  );

  List<EconomicEvent> upcomingEvents = [];
  List<EconomicEvent> completedEvents = [];
  bool isLoading = false;

  /// Get economic calendar
  Future<void> getEconomicCalendar({
    required String countryCode,
    int daysAhead = 7,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      List<Map<String, dynamic>> events =
          await newsAPI.getEconomicCalendar(
        countryCode: countryCode,
        daysAhead: daysAhead,
      );

      upcomingEvents.clear();
      for (Map<String, dynamic> event in events) {
        upcomingEvents.add(EconomicEvent(
          name: event['event'] ?? '',
          country: event['country'] ?? '',
          countryCode: countryCode,
          dateTime: DateTime.parse(event['time'] ?? DateTime.now().toString()),
          impact: EconomicImpact.values[event['impact'] ?? 0],
          forecast: event['forecast'],
          previous: event['previous'],
          actual: event['actual'],
          description: '',
        ));
      }

      // Sort by date
      upcomingEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      notifyListeners();
    } catch (e) {
      print('Error getting economic calendar: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  /// Get high impact events
  List<EconomicEvent> getHighImpactEvents() {
    return upcomingEvents
        .where((e) => e.impact == EconomicImpact.high)
        .toList();
  }

  /// Check untuk upcoming events dalam N jam
  List<EconomicEvent> getUpcomingEventsInHours(int hours) {
    DateTime now = DateTime.now();
    DateTime future = now.add(Duration(hours: hours));

    return upcomingEvents
        .where((e) => e.dateTime.isAfter(now) && e.dateTime.isBefore(future))
        .toList();
  }
}