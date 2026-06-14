// lib/services/api/news_api.dart

import 'package:dio/dio.dart';
import '../models/sentiment.dart';

enum NewsSource { finnhub, newsapi, tradingview, forexfactory }

class NewsAPI {
  final NewsSource source;
  final String apiKey;
  final Dio dio;

  NewsAPI({
    required this.source,
    required this.apiKey,
  }) : dio = Dio();

  /// Get latest news untuk pair tertentu
  Future<List<Map<String, dynamic>>> getNews({
    required String pair,
    int limit = 10,
  }) async {
    try {
      switch (source) {
        case NewsSource.finnhub:
          return await _getFinnhubNews(pair, limit);
        case NewsSource.newsapi:
          return await _getNewsAPINews(pair, limit);
        case NewsSource.tradingview:
          return await _getTradingViewNews(pair, limit);
        case NewsSource.forexfactory:
          return await _getForexFactoryNews(pair, limit);
      }
    } catch (e) {
      print('Error getting news: $e');
      return [];
    }
  }

  /// Get economic calendar events
  Future<List<Map<String, dynamic>>> getEconomicCalendar({
    required String countryCode,
    int daysAhead = 7,
  }) async {
    try {
      switch (source) {
        case NewsSource.finnhub:
          return await _getFinnhubCalendar(countryCode, daysAhead);
        case NewsSource.forexfactory:
          return await _getForexFactoryCalendar(countryCode, daysAhead);
        default:
          return [];
      }
    } catch (e) {
      print('Error getting calendar: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Finnhub Implementation
  // ════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _getFinnhubNews(
    String pair,
    int limit,
  ) async {
    try {
      // Convert EUR/USD ke EURUSD untuk Finnhub
      String symbol = pair.replaceAll('/', '');

      final response = await dio.get(
        'https://finnhub.io/api/v1/news',
        queryParameters: {
          'category': 'forex',
          'minId': 0,
          'token': apiKey,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data ?? [];
        
        // Filter by pair
        return data
          .where((n) => n['headline'].toString().toUpperCase().contains(symbol))
          .take(limit)
          .map((n) => {
            'title': n['headline'] ?? '',
            'summary': n['summary'] ?? '',
            'source': n['source'] ?? '',
            'url': n['url'] ?? '',
            'image': n['image'] ?? '',
            'publishedAt': n['datetime'] ?? DateTime.now().toString(),
            'sentiment': null, // Will be calculated separately
          })
          .toList();
      }
    } catch (e) {
      print('Finnhub News Error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _getFinnhubCalendar(
    String countryCode,
    int daysAhead,
  ) async {
    try {
      final response = await dio.get(
        'https://finnhub.io/api/v1/economic_calendar',
        queryParameters: {
          'token': apiKey,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data ?? [];
        DateTime now = DateTime.now();
        DateTime future = now.add(Duration(days: daysAhead));

        return data
          .where((event) {
            try {
              DateTime eventTime = DateTime.parse(event['time']);
              return eventTime.isAfter(now) && eventTime.isBefore(future) &&
                  event['country'].toString().toUpperCase() == countryCode;
            } catch (e) {
              return false;
            }
          })
          .map((e) => {
            'event': e['event'] ?? '',
            'country': e['country'] ?? '',
            'impact': e['impact'] ?? 'low',
            'forecast': e['forecast'],
            'previous': e['previous'],
            'actual': e['actual'],
            'time': e['time'] ?? '',
            'unit': e['unit'] ?? '',
          })
          .toList();
      }
    } catch (e) {
      print('Finnhub Calendar Error: $e');
    }
    return [];
  }

  // ════════════════════════════════════════════════════════════════
  // NewsAPI Implementation
  // ════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _getNewsAPINews(
    String pair,
    int limit,
  ) async {
    try {
      // Split pair: EUR/USD -> search for EUR and USD
      List<String> currencies = pair.split('/');
      String searchQuery = '${currencies[0]} ${currencies[1]} forex';

      final response = await dio.get(
        'https://newsapi.org/v2/everything',
        queryParameters: {
          'q': searchQuery,
          'sortBy': 'publishedAt',
          'language': 'en',
          'pageSize': limit,
          'apiKey': apiKey,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['articles'] ?? [];
        return data.map((n) => {
          'title': n['title'] ?? '',
          'summary': n['description'] ?? '',
          'source': n['source']['name'] ?? '',
          'url': n['url'] ?? '',
          'image': n['urlToImage'] ?? '',
          'publishedAt': n['publishedAt'] ?? DateTime.now().toString(),
          'content': n['content'] ?? '',
        }).toList();
      }
    } catch (e) {
      print('NewsAPI Error: $e');
    }
    return [];
  }

  // ════════════════════════════════════════════════════════════════
  // TradingView Implementation
  // ════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _getTradingViewNews(
    String pair,
    int limit,
  ) async {
    try {
      final response = await dio.get(
        'https://api.tradingview.com/news',
        queryParameters: {
          'symbols': pair,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data ?? [];
        return data.map((n) => {
          'title': n['title'] ?? '',
          'summary': n['description'] ?? '',
          'source': n['source'] ?? '',
          'url': n['url'] ?? '',
          'publishedAt': n['date'] ?? DateTime.now().toString(),
        }).toList();
      }
    } catch (e) {
      print('TradingView News Error: $e');
    }
    return [];
  }

  // ════════════════════════════════════════════════════════════════
  // Forex Factory Implementation
  // ════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _getForexFactoryNews(
    String pair,
    int limit,
  ) async {
    try {
      // Forex Factory menggunakan screen scraping (tidak ideal tapi berfungsi)
      final response = await dio.get(
        'https://www.forexfactory.com/calendar.php?month=current',
      );

      if (response.statusCode == 200) {
        // Parse HTML (simple extraction)
        String html = response.data;
        // Implement parsing logic sesuai struktur HTML
        // Ini adalah simplified version
        return [];
      }
    } catch (e) {
      print('Forex Factory Error: $e');
    }
    return [];
  }

  // ════════════════════════════════════════════════════════════════
  // Sentiment Analyzer
  // ════════════════════════════════════════════════════════════════

  /// Analyze sentiment dari news dan social media
  Future<Sentiment?> analyzeSentiment({
    required String pair,
    required List<Map<String, dynamic>> newsItems,
  }) async {
    if (newsItems.isEmpty) {
      return Sentiment(
        pair: pair,
        score: SentimentScore.neutral,
        scoreValue: 0,
        source: 'news_analysis',
        timestamp: DateTime.now(),
        keywords: [],
        newsCount: 0,
        summary: 'No news data available',
      );
    }

    double totalSentiment = 0;
    List<String> allKeywords = [];
    int positiveCount = 0;
    int negativeCount = 0;
    int neutralCount = 0;

    for (Map<String, dynamic> news in newsItems) {
      String text = '${news['title'] ?? ''} ${news['summary'] ?? ''}';
      double sentiment = _analyzeSentimentText(text);
      totalSentiment += sentiment;

      // Extract keywords
      List<String> keywords = _extractKeywords(text, pair);
      allKeywords.addAll(keywords);

      // Count sentiments
      if (sentiment > 0.2) positiveCount++;
      else if (sentiment < -0.2) negativeCount++;
      else neutralCount++;
    }

    double averageSentiment = totalSentiment / newsItems.length;

    return Sentiment(
      pair: pair,
      score: Sentiment.scoreFromValue(averageSentiment),
      scoreValue: averageSentiment.clamp(-1, 1),
      source: 'multi_source',
      timestamp: DateTime.now(),
      keywords: allKeywords.toSet().toList(),
      newsCount: newsItems.length,
      summary: 'Positive: $positiveCount, Negative: $negativeCount, Neutral: $neutralCount',
    );
  }

  /// Simple sentiment analysis menggunakan keyword matching
  double _analyzeSentimentText(String text) {
    text = text.toLowerCase();

    // Positive keywords
    List<String> positiveWords = [
      'bullish', 'rally', 'surge', 'strong', 'gain', 'jump', 'soar',
      'breakthrough', 'upside', 'advance', 'higher', 'recovery', 'boom',
      'positive', 'opportunity', 'growth', 'strength',
    ];

    // Negative keywords
    List<String> negativeWords = [
      'bearish', 'decline', 'fall', 'weak', 'loss', 'plunge', 'crash',
      'breakdown', 'downside', 'retreat', 'lower', 'sell-off', 'bust',
      'negative', 'threat', 'weakness', 'risk', 'bearish', 'dump',
    ];

    int positiveScore = 0;
    int negativeScore = 0;

    for (String word in positiveWords) {
      if (text.contains(word)) positiveScore += 1;
    }

    for (String word in negativeWords) {
      if (text.contains(word)) negativeScore += 1;
    }

    if (positiveScore + negativeScore == 0) return 0;

    return (positiveScore - negativeScore) / (positiveScore + negativeScore);
  }

  /// Extract keywords dari text
  List<String> _extractKeywords(String text, String pair) {
    List<String> keywords = [];
    List<String> currencies = pair.split('/');

    // Extract currency mentions
    if (text.toUpperCase().contains(currencies[0])) {
      keywords.add(currencies[0]);
    }
    if (text.toUpperCase().contains(currencies[1])) {
      keywords.add(currencies[1]);
    }

    // Extract economic terms
    List<String> economicTerms = [
      'inflation', 'gdp', 'employment', 'rate', 'policy', 'fed',
      'ecb', 'boe', 'central bank', 'interest', 'monetary',
    ];

    for (String term in economicTerms) {
      if (text.contains(term)) {
        keywords.add(term);
      }
    }

    return keywords;
  }

  /// Get social media sentiment (simplified)
  /// Dalam implementasi real, gunakan Twitter API v2, Reddit API, dll
  Future<double> getSocialMediaSentiment(String pair) async {
    // Placeholder untuk social media sentiment
    // Implementasi real memerlukan:
    // 1. Twitter API v2 untuk tweet analysis
    // 2. Reddit API untuk subreddit analysis
    // 3. TradingView sentiment meter
    
    return 0.5; // Neutral sentiment
  }

  /// Calculate market sentiment score (0-100)
  /// Menggabungkan berbagai sources
  Future<double> getMarketSentimentScore(String pair) async {
    try {
      // Get news sentiment
      List<Map<String, dynamic>> news = await getNews(pair: pair);
      Sentiment? newsSentiment = await analyzeSentiment(pair: pair, newsItems: news);

      // Get social media sentiment
      double socialSentiment = await getSocialMediaSentiment(pair);

      // Weighted calculation
      double newsWeight = 0.6;
      double socialWeight = 0.4;

      double finalScore = ((newsSentiment?.scoreValue ?? 0) * newsWeight +
          (socialSentiment * 2 - 1) * socialWeight) * 50 + 50;

      return finalScore.clamp(0, 100);
    } catch (e) {
      print('Error calculating sentiment: $e');
      return 50; // Neutral
    }
  }
}