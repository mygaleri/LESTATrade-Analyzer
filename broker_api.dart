// lib/services/api/broker_api.dart

import 'package:dio/dio.dart';
import '../models/forex_pair.dart';
import '../models/candle.dart';

enum BrokerType { metatrader5, oanda, interactiveBrokers, mockData }

class BrokerAPI {
  final BrokerType brokerType;
  final String apiKey;
  final String accountNumber;
  final Dio dio;

  BrokerAPI({
    required this.brokerType,
    required this.apiKey,
    required this.accountNumber,
  }) : dio = Dio();

  /// Get real-time quote untuk pair tertentu
  Future<ForexPair?> getQuote(String pair) async {
    try {
      switch (brokerType) {
        case BrokerType.metatrader5:
          return await _getQuoteMT5(pair);
        case BrokerType.oanda:
          return await _getQuoteOanda(pair);
        case BrokerType.interactiveBrokers:
          return await _getQuoteIB(pair);
        case BrokerType.mockData:
          return _getMockQuote(pair);
      }
    } catch (e) {
      print('Error getting quote: $e');
      return null;
    }
  }

  /// Get historical candles untuk technical analysis
  Future<List<Candle>?> getCandles({
    required String pair,
    required String timeframe, // '1m', '5m', '1h', '4h', '1d'
    int count = 100,
  }) async {
    try {
      switch (brokerType) {
        case BrokerType.metatrader5:
          return await _getCandlesMT5(pair, timeframe, count);
        case BrokerType.oanda:
          return await _getCandlesOanda(pair, timeframe, count);
        case BrokerType.interactiveBrokers:
          return await _getCandlesIB(pair, timeframe, count);
        case BrokerType.mockData:
          return _getMockCandles(pair, count);
      }
    } catch (e) {
      print('Error getting candles: $e');
      return null;
    }
  }

  /// Get list dari available pairs
  Future<List<ForexPair>> getAvailablePairs() async {
    try {
      switch (brokerType) {
        case BrokerType.metatrader5:
          return await _getAvailablePairsMT5();
        case BrokerType.oanda:
          return await _getAvailablePairsOanda();
        case BrokerType.interactiveBrokers:
          return await _getAvailablePairsIB();
        case BrokerType.mockData:
          return _getMockPairs();
      }
    } catch (e) {
      print('Error getting pairs: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MetaTrader 5 Implementation
  // ════════════════════════════════════════════════════════════════

  Future<ForexPair?> _getQuoteMT5(String pair) async {
    try {
      // Endpoint untuk MT5 API (berbeda-beda tergantung broker)
      final response = await dio.get(
        'https://api.example.com/v1/quote',
        queryParameters: {'symbol': pair},
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      if (response.statusCode == 200) {
        return ForexPair.fromJson(response.data);
      }
    } catch (e) {
      print('MT5 Quote Error: $e');
    }
    return null;
  }

  Future<List<Candle>?> _getCandlesMT5(
    String pair,
    String timeframe,
    int count,
  ) async {
    try {
      final response = await dio.get(
        'https://api.example.com/v1/candles',
        queryParameters: {
          'symbol': pair,
          'timeframe': timeframe,
          'limit': count,
        },
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['candles'] ?? [];
        return data.map((c) => Candle.fromJson(c)).toList();
      }
    } catch (e) {
      print('MT5 Candles Error: $e');
    }
    return null;
  }

  Future<List<ForexPair>> _getAvailablePairsMT5() async {
    try {
      final response = await dio.get(
        'https://api.example.com/v1/symbols',
        queryParameters: {'type': 'forex'},
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['symbols'] ?? [];
        return data.map((p) => ForexPair.fromJson(p)).toList();
      }
    } catch (e) {
      print('MT5 Pairs Error: $e');
    }
    return [];
  }

  // ════════════════════════════════════════════════════════════════
  // Oanda Implementation
  // ════════════════════════════════════════════════════════════════

  Future<ForexPair?> _getQuoteOanda(String pair) async {
    try {
      // Oanda REST API v20
      final response = await dio.get(
        'https://api-fxpractice.oanda.com/v3/accounts/$accountNumber/pricing',
        queryParameters: {'instruments': pair},
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        var data = response.data['prices'][0];
        return ForexPair(
          symbol: data['instrument'],
          name: data['instrument'],
          bid: double.parse(data['bids'][0]['price']),
          ask: double.parse(data['asks'][0]['price']),
          change: 0,
          changeAmount: 0,
          lastUpdate: DateTime.now(),
        );
      }
    } catch (e) {
      print('Oanda Quote Error: $e');
    }
    return null;
  }

  Future<List<Candle>?> _getCandlesOanda(
    String pair,
    String timeframe,
    int count,
  ) async {
    try {
      // Map timeframe ke Oanda format
      String oandaTimeframe = _mapTimeframeToOanda(timeframe);

      final response = await dio.get(
        'https://api-fxpractice.oanda.com/v3/instruments/$pair/candles',
        queryParameters: {
          'granularity': oandaTimeframe,
          'count': count,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['candles'] ?? [];
        return data.map((c) => Candle(
          time: DateTime.parse(c['time']),
          open: double.parse(c['mid']['o']),
          high: double.parse(c['mid']['h']),
          low: double.parse(c['mid']['l']),
          close: double.parse(c['mid']['c']),
          volume: double.parse(c['volume'].toString()),
        )).toList();
      }
    } catch (e) {
      print('Oanda Candles Error: $e');
    }
    return null;
  }

  Future<List<ForexPair>> _getAvailablePairsOanda() async {
    try {
      final response = await dio.get(
        'https://api-fxpractice.oanda.com/v3/accounts/$accountNumber/instruments',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['instruments'] ?? [];
        return data
          .where((i) => i['type'] == 'CURRENCY')
          .map((i) => ForexPair(
            symbol: i['name'],
            name: i['displayName'] ?? i['name'],
            bid: 0,
            ask: 0,
            change: 0,
            changeAmount: 0,
            lastUpdate: DateTime.now(),
          ))
          .toList();
      }
    } catch (e) {
      print('Oanda Pairs Error: $e');
    }
    return [];
  }

  String _mapTimeframeToOanda(String timeframe) {
    switch (timeframe) {
      case '1m': return 'M1';
      case '5m': return 'M5';
      case '15m': return 'M15';
      case '30m': return 'M30';
      case '1h': return 'H1';
      case '4h': return 'H4';
      case '1d': return 'D';
      case '1w': return 'W';
      case '1mo': return 'M';
      default: return 'H1';
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Interactive Brokers Implementation
  // ════════════════════════════════════════════════════════════════

  Future<ForexPair?> _getQuoteIB(String pair) async {
    try {
      // Interactive Brokers API endpoint
      final response = await dio.get(
        'https://api.ibkr.com/v1/marketdata/snapshot',
        queryParameters: {
          'conid': _getIBContractId(pair),
          'fields': '7,8,9,12',
        },
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      if (response.statusCode == 200) {
        return ForexPair.fromJson(response.data[0]);
      }
    } catch (e) {
      print('IB Quote Error: $e');
    }
    return null;
  }

  Future<List<Candle>?> _getCandlesIB(
    String pair,
    String timeframe,
    int count,
  ) async {
    try {
      String ibTimeframe = _mapTimeframeToIB(timeframe);

      final response = await dio.get(
        'https://api.ibkr.com/v1/marketdata/history',
        queryParameters: {
          'conid': _getIBContractId(pair),
          'period': '${count}d',
          'bar': ibTimeframe,
        },
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'] ?? [];
        return data.map((c) => Candle.fromJson(c)).toList();
      }
    } catch (e) {
      print('IB Candles Error: $e');
    }
    return null;
  }

  Future<List<ForexPair>> _getAvailablePairsIB() async {
    // Hardcoded list atau dapat dari API
    return [
      ForexPair(
        symbol: 'EUR.USD',
        name: 'EUR/USD',
        bid: 0,
        ask: 0,
        change: 0,
        changeAmount: 0,
        lastUpdate: DateTime.now(),
      ),
      // ... more pairs
    ];
  }

  String _mapTimeframeToIB(String timeframe) {
    switch (timeframe) {
      case '1m': return '1';
      case '5m': return '5';
      case '15m': return '15';
      case '30m': return '30';
      case '1h': return '60';
      case '4h': return '240';
      case '1d': return '1D';
      default: return '60';
    }
  }

  int _getIBContractId(String pair) {
    // Map pair ke contract ID
    // Ini biasanya dari API atau local mapping
    Map<String, int> contractIds = {
      'EUR.USD': 12087792,
      'GBP.USD': 12087820,
      // ... more pairs
    };
    return contractIds[pair] ?? 12087792;
  }

  // ════════════════════════════════════════════════════════════════
  // Mock Data untuk Testing/Development
  // ════════════════════════════════════════════════════════════════

  ForexPair? _getMockQuote(String pair) {
    return ForexPair(
      symbol: pair,
      name: pair,
      bid: 1.1050,
      ask: 1.1052,
      change: 0.45,
      changeAmount: 0.0050,
      lastUpdate: DateTime.now(),
    );
  }

  List<Candle> _getMockCandles(String pair, int count) {
    List<Candle> candles = [];
    double basePrice = 1.1050;

    for (int i = count; i > 0; i--) {
      double open = basePrice + (i * 0.0001);
      double close = open + (0.0005 * (i % 2 == 0 ? 1 : -1));
      double high = open > close ? open : close + 0.0010;
      double low = open < close ? open : close - 0.0010;

      candles.add(Candle(
        time: DateTime.now().subtract(Duration(hours: i)),
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 1000000 + (i * 10000),
      ));
    }

    return candles;
  }

  List<ForexPair> _getMockPairs() {
    return [
      ForexPair(
        symbol: 'EUR/USD',
        name: 'Euro / US Dollar',
        bid: 1.1050,
        ask: 1.1052,
        change: 0.45,
        changeAmount: 0.0050,
        lastUpdate: DateTime.now(),
      ),
      ForexPair(
        symbol: 'GBP/USD',
        name: 'British Pound / US Dollar',
        bid: 1.2700,
        ask: 1.2702,
        change: -0.30,
        changeAmount: -0.0040,
        lastUpdate: DateTime.now(),
      ),
      ForexPair(
        symbol: 'USD/JPY',
        name: 'US Dollar / Japanese Yen',
        bid: 110.50,
        ask: 110.52,
        change: 0.15,
        changeAmount: 0.15,
        lastUpdate: DateTime.now(),
      ),
    ];
  }
}