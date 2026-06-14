// lib/services/indicators/technical_indicators.dart

import 'dart:math';
import '../models/candle.dart';
import '../models/indicator_values.dart';

class TechnicalIndicators {
  
  /// Calculate Relative Strength Index (RSI)
  /// Period biasanya 14
  /// Mengukur momentum dan overbought/oversold conditions
  static double calculateRSI({
    required List<double> prices,
    required int period,
  }) {
    if (prices.length < period + 1) return 50; // Default neutral

    List<double> changes = [];
    for (int i = 1; i < prices.length; i++) {
      changes.add(prices[i] - prices[i - 1]);
    }

    double avgGain = 0;
    double avgLoss = 0;

    for (int i = 0; i < period; i++) {
      if (changes[i] > 0) {
        avgGain += changes[i];
      } else {
        avgLoss += changes[i].abs();
      }
    }

    avgGain /= period;
    avgLoss /= period;

    // Smoothed average untuk performa lebih baik
    for (int i = period; i < changes.length; i++) {
      if (changes[i] > 0) {
        avgGain = (avgGain * (period - 1) + changes[i]) / period;
        avgLoss = (avgLoss * (period - 1)) / period;
      } else {
        avgGain = (avgGain * (period - 1)) / period;
        avgLoss = (avgLoss * (period - 1) + changes[i].abs()) / period;
      }
    }

    if (avgLoss == 0) {
      return avgGain == 0 ? 50 : 100;
    }

    double rs = avgGain / avgLoss;
    double rsi = 100 - (100 / (1 + rs));

    return rsi.clamp(0, 100);
  }

  /// Calculate Moving Average Convergence Divergence (MACD)
  /// Trend following momentum indicator
  static Map<String, double> calculateMACD({
    required List<double> prices,
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    if (prices.length < slowPeriod) {
      return {
        'macdLine': 0,
        'signalLine': 0,
        'histogram': 0,
      };
    }

    double fastEMA = calculateEMA(prices.sublist(0, fastPeriod), fastPeriod);
    double slowEMA = calculateEMA(prices, slowPeriod);
    
    double macdLine = fastEMA - slowEMA;
    
    // Untuk signal line, kita perlu lebih banyak data
    // Simplified version
    double signalLine = macdLine * 0.5; // Placeholder
    double histogram = macdLine - signalLine;

    return {
      'macdLine': macdLine,
      'signalLine': signalLine,
      'histogram': histogram,
    };
  }

  /// Calculate Exponential Moving Average (EMA)
  static double calculateEMA(List<double> prices, int period) {
    if (prices.isEmpty) return 0;
    if (prices.length < period) {
      return prices.reduce((a, b) => a + b) / prices.length;
    }

    double multiplier = 2 / (period + 1);
    double ema = prices.sublist(0, period).reduce((a, b) => a + b) / period;

    for (int i = period; i < prices.length; i++) {
      ema = (prices[i] * multiplier) + (ema * (1 - multiplier));
    }

    return ema;
  }

  /// Calculate Simple Moving Average (SMA)
  static double calculateSMA(List<double> prices, int period) {
    if (prices.length < period) return 0;
    
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    return sum / period;
  }

  /// Calculate Bollinger Bands
  /// Terdiri dari SMA middle band dan upper/lower bands (2 std dev)
  static Map<String, double> calculateBollingerBands({
    required List<double> prices,
    int period = 20,
    double stdDevMultiplier = 2,
  }) {
    if (prices.length < period) {
      return {
        'upper': 0,
        'middle': 0,
        'lower': 0,
      };
    }

    // Hitung SMA untuk middle band
    double middle = calculateSMA(prices, period);

    // Hitung standard deviation
    List<double> recentPrices = prices.sublist(prices.length - period);
    double variance = 0;
    
    for (double price in recentPrices) {
      variance += pow(price - middle, 2).toDouble();
    }
    variance /= period;
    double stdDev = sqrt(variance);

    double upper = middle + (stdDev * stdDevMultiplier);
    double lower = middle - (stdDev * stdDevMultiplier);

    return {
      'upper': upper,
      'middle': middle,
      'lower': lower,
    };
  }

  /// Calculate Stochastic Oscillator
  /// Measure momentum, values 0-100
  /// %K = (Close - Low) / (High - Low) * 100
  static double calculateStochastic({
    required List<Candle> candles,
    int period = 14,
  }) {
    if (candles.length < period) return 50;

    List<Candle> recent = candles.sublist(candles.length - period);
    
    double highest = recent.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double lowest = recent.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double currentClose = candles.last.close;

    if (highest == lowest) return 50;

    double stochastic = ((currentClose - lowest) / (highest - lowest)) * 100;
    return stochastic.clamp(0, 100);
  }

  /// Calculate Average True Range (ATR)
  /// Mengukur volatility
  static double calculateATR({
    required List<Candle> candles,
    int period = 14,
  }) {
    if (candles.length < period) return 0;

    List<double> trueRanges = [];
    
    for (int i = 0; i < candles.length; i++) {
      double tr;
      if (i == 0) {
        tr = candles[i].high - candles[i].low;
      } else {
        double tr1 = candles[i].high - candles[i].low;
        double tr2 = (candles[i].high - candles[i - 1].close).abs();
        double tr3 = (candles[i].low - candles[i - 1].close).abs();
        tr = max(tr1, max(tr2, tr3));
      }
      trueRanges.add(tr);
    }

    // Calculate ATR using EMA
    double atr = 0;
    for (int i = 0; i < period; i++) {
      atr += trueRanges[i];
    }
    atr /= period;

    double multiplier = 2 / (period + 1);
    for (int i = period; i < trueRanges.length; i++) {
      atr = (trueRanges[i] * multiplier) + (atr * (1 - multiplier));
    }

    return atr;
  }

  /// Calculate PSAR (Parabolic SAR)
  /// Trend-following indicator
  static List<double> calculateParabolicSAR({
    required List<Candle> candles,
    int lookback = 14,
  }) {
    if (candles.length < lookback) return [];

    List<double> sar = [];
    List<Candle> recent = candles.sublist(candles.length - lookback);

    double highest = recent.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double lowest = recent.map((c) => c.low).reduce((a, b) => a < b ? a : b);

    double sarValue = lowest;
    double af = 0.02; // Acceleration Factor start
    double maxAF = 0.2;

    // Simplified SAR calculation
    for (Candle candle in recent) {
      if (candle.close > sarValue) {
        sarValue = highest;
        af = min(af + 0.02, maxAF);
      } else {
        sarValue = lowest;
        af = 0.02;
      }
      sar.add(sarValue);
    }

    return sar;
  }

  /// Multi-period analysis
  /// Analyze dengan berbagai timeframe untuk confirmation
  static Map<String, dynamic> analyzeMultiPeriod({
    required List<Candle> dailyCandles,
    required List<Candle> hourlyCandles,
    required List<Candle> fifteenMinCandles,
  }) {
    // Ambil close prices
    List<double> dailyClose = dailyCandles.map((c) => c.close).toList();
    List<double> hourlyClose = hourlyCandles.map((c) => c.close).toList();
    List<double> fifteenMinClose = fifteenMinCandles.map((c) => c.close).toList();

    // Calculate indicators untuk setiap timeframe
    Map<String, dynamic> analysis = {
      'daily': {
        'rsi': calculateRSI(prices: dailyClose, period: 14),
        'macd': calculateMACD(prices: dailyClose),
        'bb': calculateBollingerBands(prices: dailyClose),
        'sma50': calculateSMA(dailyClose, 50),
        'sma200': calculateSMA(dailyClose, 200),
      },
      'hourly': {
        'rsi': calculateRSI(prices: hourlyClose, period: 14),
        'macd': calculateMACD(prices: hourlyClose),
        'stoch': calculateStochastic(candles: hourlyCandles),
      },
      '15min': {
        'rsi': calculateRSI(prices: fifteenMinClose, period: 14),
        'stoch': calculateStochastic(candles: fifteenMinCandles),
      },
    };

    return analysis;
  }
}

// lib/services/indicators/calculations.dart
class IndicatorCalculations {
  
  /// Calculate Fibonacci Retracement levels
  static Map<String, double> calculateFibonacci({
    required double highPrice,
    required double lowPrice,
  }) {
    double difference = highPrice - lowPrice;

    return {
      '0%': highPrice,
      '23.6%': highPrice - (difference * 0.236),
      '38.2%': highPrice - (difference * 0.382),
      '50%': highPrice - (difference * 0.5),
      '61.8%': highPrice - (difference * 0.618),
      '100%': lowPrice,
    };
  }

  /// Calculate Support & Resistance levels
  static Map<String, double> calculateSupportResistance({
    required List<Candle> candles,
  }) {
    if (candles.isEmpty) return {};

    List<double> highs = candles.map((c) => c.high).toList();
    List<double> lows = candles.map((c) => c.low).toList();

    double currentPrice = candles.last.close;
    double resistance1 = highs.reduce((a, b) => a > b ? a : b);
    double support1 = lows.reduce((a, b) => a < b ? a : b);
    double pivot = (resistance1 + support1 + currentPrice) / 3;
    double resistance2 = (pivot * 2) - support1;
    double support2 = (pivot * 2) - resistance1;

    return {
      'resistance2': resistance2,
      'resistance1': resistance1,
      'pivot': pivot,
      'support1': support1,
      'support2': support2,
    };
  }

  /// Calculate Risk:Reward Ratio
  static double calculateRiskReward({
    required double entryPrice,
    required double stopLoss,
    required double takeProfit,
  }) {
    double risk = (entryPrice - stopLoss).abs();
    double reward = (takeProfit - entryPrice).abs();

    if (risk == 0) return 0;
    return reward / risk;
  }
}