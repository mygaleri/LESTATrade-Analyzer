// lib/services/indicators/signal_generator.dart

import '../models/signal.dart';
import '../models/candle.dart';
import '../models/indicator_values.dart';
import 'technical_indicators.dart';

class SignalGenerator {
  
  /// Generate trading signals berdasarkan multiple indicators
  /// Menggabungkan RSI, MACD, Moving Averages, Bollinger Bands
  static Signal? generateSignal({
    required String pair,
    required List<Candle> candles,
    required IndicatorValues indicators,
    required double currentPrice,
  }) {
    if (candles.isEmpty) return null;

    List<String> buySignals = [];
    List<String> sellSignals = [];
    int totalConfirmations = 0;

    // 1. RSI Analysis
    if (indicators.rsi < 30) {
      buySignals.add('RSI Oversold');
      totalConfirmations++;
    } else if (indicators.rsi > 70) {
      sellSignals.add('RSI Overbought');
      totalConfirmations++;
    }

    // 2. MACD Analysis
    if (indicators.macdLine > indicators.macdSignal && 
        indicators.macdHistogram > 0) {
      buySignals.add('MACD Bullish');
      totalConfirmations++;
    } else if (indicators.macdLine < indicators.macdSignal && 
               indicators.macdHistogram < 0) {
      sellSignals.add('MACD Bearish');
      totalConfirmations++;
    }

    // 3. Moving Average Analysis
    if (currentPrice > indicators.sma50 && 
        indicators.sma50 > indicators.sma200) {
      buySignals.add('MA Uptrend');
      totalConfirmations++;
    } else if (currentPrice < indicators.sma50 && 
               indicators.sma50 < indicators.sma200) {
      sellSignals.add('MA Downtrend');
      totalConfirmations++;
    }

    // 4. Bollinger Bands Analysis
    if (currentPrice < indicators.bb_lower) {
      buySignals.add('BB Lower Band Bounce');
      totalConfirmations++;
    } else if (currentPrice > indicators.bb_upper) {
      sellSignals.add('BB Upper Band Rejection');
      totalConfirmations++;
    }

    // 5. Candlestick Pattern Analysis
    String? candlePattern = analyzeCandlePatterns(candles);
    if (candlePattern != null) {
      if (candlePattern.contains('bullish')) {
        buySignals.add(candlePattern);
        totalConfirmations++;
      } else if (candlePattern.contains('bearish')) {
        sellSignals.add(candlePattern);
        totalConfirmations++;
      }
    }

    // Determine signal berdasarkan signals yang collected
    if (buySignals.isEmpty && sellSignals.isEmpty) {
      return null;
    }

    // Generate signal dengan confidence berdasarkan jumlah confirmations
    double confidence = (totalConfirmations / 5) * 100; // Max 5 indicators
    
    if (buySignals.length > sellSignals.length) {
      SignalType signalType = buySignals.length >= 3 
        ? SignalType.strongBuy 
        : SignalType.buy;

      return Signal(
        type: signalType,
        source: SignalSource.combination,
        pair: pair,
        price: currentPrice,
        timestamp: DateTime.now(),
        confidence: confidence.clamp(0, 100),
        description: 'Buy Signal: ${buySignals.join(", ")}',
        indicators: buySignals,
        strength: buySignals.length,
        takeProfitLevel: calculateTakeProfit(
          entryPrice: currentPrice,
          atr: calculateATRFromCandles(candles),
          isLong: true,
        ),
        stopLossLevel: calculateStopLoss(
          entryPrice: currentPrice,
          atr: calculateATRFromCandles(candles),
          isLong: true,
        ),
      );
    } else {
      SignalType signalType = sellSignals.length >= 3 
        ? SignalType.strongSell 
        : SignalType.sell;

      return Signal(
        type: signalType,
        source: SignalSource.combination,
        pair: pair,
        price: currentPrice,
        timestamp: DateTime.now(),
        confidence: confidence.clamp(0, 100),
        description: 'Sell Signal: ${sellSignals.join(", ")}',
        indicators: sellSignals,
        strength: sellSignals.length,
        takeProfitLevel: calculateTakeProfit(
          entryPrice: currentPrice,
          atr: calculateATRFromCandles(candles),
          isLong: false,
        ),
        stopLossLevel: calculateStopLoss(
          entryPrice: currentPrice,
          atr: calculateATRFromCandles(candles),
          isLong: false,
        ),
      );
    }
  }

  /// Analyze candlestick patterns
  static String? analyzeCandlePatterns(List<Candle> candles) {
    if (candles.length < 3) return null;

    Candle current = candles.last;
    Candle previous = candles[candles.length - 2];
    Candle twoBarsAgo = candles[candles.length - 3];

    // Hammer Pattern (Bullish)
    if (isHammer(current)) {
      return 'Bullish Hammer';
    }

    // Shooting Star Pattern (Bearish)
    if (isShootingStar(current)) {
      return 'Bearish Shooting Star';
    }

    // Engulfing Pattern
    if (isBullishEngulfing(previous, current)) {
      return 'Bullish Engulfing';
    }
    if (isBearishEngulfing(previous, current)) {
      return 'Bearish Engulfing';
    }

    // Morning Star (Bullish) / Evening Star (Bearish)
    if (isMorningStar(twoBarsAgo, previous, current)) {
      return 'Bullish Morning Star';
    }
    if (isEveningStar(twoBarsAgo, previous, current)) {
      return 'Bearish Evening Star';
    }

    return null;
  }

  /// Check untuk Hammer pattern
  /// Terbentuk pada downtrend, signal pembalikan
  static bool isHammer(Candle candle) {
    double bodySize = (candle.close - candle.open).abs();
    double lowerWick = candle.open < candle.close 
      ? candle.open - candle.low 
      : candle.close - candle.low;
    double upperWick = candle.high - (candle.open > candle.close ? candle.open : candle.close);

    // Hammer: small body, long lower wick, small upper wick
    return lowerWick > bodySize * 2 && upperWick < bodySize * 0.5;
  }

  /// Check untuk Shooting Star pattern
  /// Terbentuk pada uptrend, signal pembalikan
  static bool isShootingStar(Candle candle) {
    double bodySize = (candle.close - candle.open).abs();
    double upperWick = candle.high - (candle.open > candle.close ? candle.open : candle.close);
    double lowerWick = candle.open < candle.close 
      ? candle.open - candle.low 
      : candle.close - candle.low;

    // Shooting Star: small body, long upper wick, small lower wick
    return upperWick > bodySize * 2 && lowerWick < bodySize * 0.5;
  }

  /// Check untuk Bullish Engulfing
  static bool isBullishEngulfing(Candle previous, Candle current) {
    // Previous candle bearish (close < open)
    if (previous.close > previous.open) return false;
    
    // Current candle bullish (close > open)
    if (current.close < current.open) return false;
    
    // Current engulfs previous
    return current.open <= previous.close && current.close >= previous.open;
  }

  /// Check untuk Bearish Engulfing
  static bool isBearishEngulfing(Candle previous, Candle current) {
    // Previous candle bullish (close > open)
    if (previous.close < previous.open) return false;
    
    // Current candle bearish (close < open)
    if (current.close > current.open) return false;
    
    // Current engulfs previous
    return current.open >= previous.close && current.close <= previous.open;
  }

  /// Check untuk Morning Star (Bullish reversal)
  static bool isMorningStar(Candle candle1, Candle candle2, Candle candle3) {
    // First: bearish candle
    if (candle1.close >= candle1.open) return false;
    
    // Second: small candle (doji-like)
    double candle2Body = (candle2.close - candle2.open).abs();
    if (candle2Body > (candle1.close - candle1.open).abs() * 0.5) return false;
    
    // Third: bullish candle
    if (candle3.close <= candle3.open) return false;
    
    return true;
  }

  /// Check untuk Evening Star (Bearish reversal)
  static bool isEveningStar(Candle candle1, Candle candle2, Candle candle3) {
    // First: bullish candle
    if (candle1.close <= candle1.open) return false;
    
    // Second: small candle (doji-like)
    double candle2Body = (candle2.close - candle2.open).abs();
    if (candle2Body > (candle1.close - candle1.open).abs() * 0.5) return false;
    
    // Third: bearish candle
    if (candle3.close >= candle3.open) return false;
    
    return true;
  }

  /// Calculate Take Profit level
  static double calculateTakeProfit({
    required double entryPrice,
    required double atr,
    required bool isLong,
    double atrMultiplier = 3.0,
  }) {
    if (isLong) {
      return entryPrice + (atr * atrMultiplier);
    } else {
      return entryPrice - (atr * atrMultiplier);
    }
  }

  /// Calculate Stop Loss level
  static double calculateStopLoss({
    required double entryPrice,
    required double atr,
    required bool isLong,
    double atrMultiplier = 1.5,
  }) {
    if (isLong) {
      return entryPrice - (atr * atrMultiplier);
    } else {
      return entryPrice + (atr * atrMultiplier);
    }
  }

  /// Helper untuk calculate ATR dari candles
  static double calculateATRFromCandles(List<Candle> candles) {
    if (candles.length < 14) {
      return candles.last.high - candles.last.low;
    }
    return TechnicalIndicators.calculateATR(candles: candles, period: 14);
  }

  /// Generate RSI-based signal
  static Signal? generateRSISignal({
    required String pair,
    required double rsi,
    required double currentPrice,
  }) {
    if (rsi < 30) {
      return Signal(
        type: SignalType.buy,
        source: SignalSource.rsi,
        pair: pair,
        price: currentPrice,
        timestamp: DateTime.now(),
        confidence: 60,
        description: 'RSI Oversold at $rsi - Buy signal',
        indicators: ['RSI'],
      );
    } else if (rsi > 70) {
      return Signal(
        type: SignalType.sell,
        source: SignalSource.rsi,
        pair: pair,
        price: currentPrice,
        timestamp: DateTime.now(),
        confidence: 60,
        description: 'RSI Overbought at $rsi - Sell signal',
        indicators: ['RSI'],
      );
    }
    return null;
  }

  /// Generate MACD-based signal
  static Signal? generateMACDSignal({
    required String pair,
    required double macdLine,
    required double signalLine,
    required double currentPrice,
  }) {
    if (macdLine > signalLine) {
      return Signal(
        type: SignalType.buy,
        source: SignalSource.macd,
        pair: pair,
        price: currentPrice,
        timestamp: DateTime.now(),
        confidence: 65,
        description: 'MACD Golden Cross - Buy signal',
        indicators: ['MACD'],
      );
    } else if (macdLine < signalLine) {
      return Signal(
        type: SignalType.sell,
        source: SignalSource.macd,
        pair: pair,
        price: currentPrice,
        timestamp: DateTime.now(),
        confidence: 65,
        description: 'MACD Death Cross - Sell signal',
        indicators: ['MACD'],
      );
    }
    return null;
  }
}