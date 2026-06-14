// lib/models/forex_pair.dart
class ForexPair {
  final String symbol;        // EUR/USD
  final String name;
  final double bid;
  final double ask;
  final double change;        // Perubahan dalam %
  final double changeAmount;
  final DateTime lastUpdate;
  final bool isWatchlist;

  ForexPair({
    required this.symbol,
    required this.name,
    required this.bid,
    required this.ask,
    required this.change,
    required this.changeAmount,
    required this.lastUpdate,
    this.isWatchlist = false,
  });

  double get spread => ask - bid;
  double get mid => (bid + ask) / 2;
  bool get isUp => change > 0;

  factory ForexPair.fromJson(Map<String, dynamic> json) {
    return ForexPair(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      bid: (json['bid'] ?? 0).toDouble(),
      ask: (json['ask'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      lastUpdate: DateTime.parse(json['lastUpdate'] ?? DateTime.now().toString()),
      isWatchlist: json['isWatchlist'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'bid': bid,
    'ask': ask,
    'change': change,
    'changeAmount': changeAmount,
    'lastUpdate': lastUpdate.toIso8601String(),
    'isWatchlist': isWatchlist,
  };
}

// lib/models/candle.dart
class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close > open;
  double get bodySize => (close - open).abs();
  double get range => high - low;

  factory Candle.fromJson(Map<String, dynamic> json) {
    return Candle(
      time: DateTime.parse(json['time'] ?? DateTime.now().toString()),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'volume': volume,
  };
}

// lib/models/signal.dart
enum SignalType { buy, sell, strongBuy, strongSell, hold }
enum SignalSource { rsi, macd, movingAverage, bollinger, combination }

class Signal {
  final SignalType type;
  final SignalSource source;
  final String pair;
  final double price;
  final DateTime timestamp;
  final double confidence;     // 0-100
  final String description;
  final List<String> indicators; // Indicators yang memberikan signal
  final double? takeProfitLevel;
  final double? stopLossLevel;
  final int? strength;         // Jumlah indicator yang agree

  Signal({
    required this.type,
    required this.source,
    required this.pair,
    required this.price,
    required this.timestamp,
    required this.confidence,
    required this.description,
    required this.indicators,
    this.takeProfitLevel,
    this.stopLossLevel,
    this.strength,
  });

  bool get isBuy => type == SignalType.buy || type == SignalType.strongBuy;
  bool get isSell => type == SignalType.sell || type == SignalType.strongSell;
  bool get isStrong => type == SignalType.strongBuy || type == SignalType.strongSell;

  factory Signal.fromJson(Map<String, dynamic> json) {
    return Signal(
      type: SignalType.values[json['type'] ?? 0],
      source: SignalSource.values[json['source'] ?? 0],
      pair: json['pair'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      confidence: (json['confidence'] ?? 50).toDouble(),
      description: json['description'] ?? '',
      indicators: List<String>.from(json['indicators'] ?? []),
      takeProfitLevel: json['takeProfitLevel'] != null 
        ? (json['takeProfitLevel']).toDouble() 
        : null,
      stopLossLevel: json['stopLossLevel'] != null 
        ? (json['stopLossLevel']).toDouble() 
        : null,
      strength: json['strength'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'source': source.index,
    'pair': pair,
    'price': price,
    'timestamp': timestamp.toIso8601String(),
    'confidence': confidence,
    'description': description,
    'indicators': indicators,
    'takeProfitLevel': takeProfitLevel,
    'stopLossLevel': stopLossLevel,
    'strength': strength,
  };
}

// lib/models/sentiment.dart
enum SentimentScore { veryNegative, negative, neutral, positive, veryPositive }

class Sentiment {
  final String pair;
  final SentimentScore score;
  final double scoreValue;    // -1.0 to 1.0
  final String source;        // Dari mana data sentiment (news, twitter, dll)
  final DateTime timestamp;
  final List<String> keywords;
  final int newsCount;
  final String summary;

  Sentiment({
    required this.pair,
    required this.score,
    required this.scoreValue,
    required this.source,
    required this.timestamp,
    required this.keywords,
    required this.newsCount,
    required this.summary,
  });

  static SentimentScore scoreFromValue(double value) {
    if (value < -0.6) return SentimentScore.veryNegative;
    if (value < -0.2) return SentimentScore.negative;
    if (value < 0.2) return SentimentScore.neutral;
    if (value < 0.6) return SentimentScore.positive;
    return SentimentScore.veryPositive;
  }

  factory Sentiment.fromJson(Map<String, dynamic> json) {
    double scoreValue = (json['scoreValue'] ?? 0).toDouble();
    return Sentiment(
      pair: json['pair'] ?? '',
      score: scoreFromValue(scoreValue),
      scoreValue: scoreValue,
      source: json['source'] ?? 'unknown',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      keywords: List<String>.from(json['keywords'] ?? []),
      newsCount: json['newsCount'] ?? 0,
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'pair': pair,
    'score': score.index,
    'scoreValue': scoreValue,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
    'keywords': keywords,
    'newsCount': newsCount,
    'summary': summary,
  };
}

// lib/models/economic_event.dart
enum EconomicImpact { low, medium, high }

class EconomicEvent {
  final String name;
  final String country;
  final String countryCode;   // USD, EUR, GBP
  final DateTime dateTime;
  final EconomicImpact impact;
  final double? forecast;
  final double? previous;
  final double? actual;
  final String description;

  EconomicEvent({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.dateTime,
    required this.impact,
    this.forecast,
    this.previous,
    this.actual,
    required this.description,
  });

  bool get isReleased => actual != null;
  bool get isBeatExpectation => 
    actual != null && forecast != null && actual! > forecast!;

  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    return EconomicEvent(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['countryCode'] ?? '',
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toString()),
      impact: EconomicImpact.values[json['impact'] ?? 0],
      forecast: json['forecast'] != null ? (json['forecast']).toDouble() : null,
      previous: json['previous'] != null ? (json['previous']).toDouble() : null,
      actual: json['actual'] != null ? (json['actual']).toDouble() : null,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'countryCode': countryCode,
    'dateTime': dateTime.toIso8601String(),
    'impact': impact.index,
    'forecast': forecast,
    'previous': previous,
    'actual': actual,
    'description': description,
  };
}

// lib/models/indicator_values.dart
class IndicatorValues {
  final double rsi;           // 0-100
  final double macdLine;      // Can be any value
  final double macdSignal;
  final double macdHistogram;
  final double bb_upper;      // Bollinger Band upper
  final double bb_middle;     // SMA
  final double bb_lower;      // Bollinger Band lower
  final double sma20;         // Simple Moving Average 20
  final double sma50;         // Simple Moving Average 50
  final double sma200;        // Simple Moving Average 200
  final DateTime timestamp;

  IndicatorValues({
    required this.rsi,
    required this.macdLine,
    required this.macdSignal,
    required this.macdHistogram,
    required this.bb_upper,
    required this.bb_middle,
    required this.bb_lower,
    required this.sma20,
    required this.sma50,
    required this.sma200,
    required this.timestamp,
  });

  // Helper untuk interpretasi RSI
  bool get isOverbought => rsi > 70;
  bool get isOversold => rsi < 30;
  
  // Helper untuk MACD
  bool get macdPositive => macdLine > macdSignal;
  
  // Helper untuk Bollinger Bands
  bool get priceNearUpper => false; // Akan dihitung dari price actual

  factory IndicatorValues.fromJson(Map<String, dynamic> json) {
    return IndicatorValues(
      rsi: (json['rsi'] ?? 50).toDouble(),
      macdLine: (json['macdLine'] ?? 0).toDouble(),
      macdSignal: (json['macdSignal'] ?? 0).toDouble(),
      macdHistogram: (json['macdHistogram'] ?? 0).toDouble(),
      bb_upper: (json['bb_upper'] ?? 0).toDouble(),
      bb_middle: (json['bb_middle'] ?? 0).toDouble(),
      bb_lower: (json['bb_lower'] ?? 0).toDouble(),
      sma20: (json['sma20'] ?? 0).toDouble(),
      sma50: (json['sma50'] ?? 0).toDouble(),
      sma200: (json['sma200'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'rsi': rsi,
    'macdLine': macdLine,
    'macdSignal': macdSignal,
    'macdHistogram': macdHistogram,
    'bb_upper': bb_upper,
    'bb_middle': bb_middle,
    'bb_lower': bb_lower,
    'sma20': sma20,
    'sma50': sma50,
    'sma200': sma200,
    'timestamp': timestamp.toIso8601String(),
  };
}