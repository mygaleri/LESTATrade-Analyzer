// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/forex_provider.dart';
import 'providers/signals_provider.dart';
import 'providers/sentiment_provider.dart';
import 'screens/home_screen.dart';
import 'utils/color_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive untuk local storage
  await Hive.initFlutter();
  await Hive.openBox('watchlist');
  await Hive.openBox('settings');
  await Hive.openBox('signals_history');
  
  runApp(const ForexAnalyzerApp());
}

class ForexAnalyzerApp extends StatelessWidget {
  const ForexAnalyzerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ForexProvider()),
        ChangeNotifierProvider(create: (_) => SignalsProvider()),
        ChangeNotifierProvider(create: (_) => SentimentProvider()),
      ],
      child: MaterialApp(
        title: 'Forex Analyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.darkBg,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.darkCard,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardTheme(
            color: AppColors.darkCard,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            headlineSmall: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forex_provider.dart';
import '../providers/signals_provider.dart';
import '../providers/sentiment_provider.dart';
import '../widgets/chart_widget.dart';
import '../widgets/signal_card.dart';
import '../widgets/sentiment_gauge.dart';
import '../utils/color_themes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentPairIndex = 0;

  final List<String> pairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'USD/CHF',
    'AUD/USD',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ForexProvider>(context, listen: false)
          .startRealTimeUpdates();
      Provider.of<SignalsProvider>(context, listen: false)
          .generateSignals();
      Provider.of<SentimentProvider>(context, listen: false)
          .analyzeSentiment(pairs[_currentPairIndex]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forex Analyzer'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ════════════════════════════════════════════════════════
            // Pair Selector
            // ════════════════════════════════════════════════════════
            Container(
              height: 60,
              color: AppColors.darkCard,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: pairs.length,
                itemBuilder: (context, index) {
                  final isSelected = _currentPairIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentPairIndex = index);
                      Provider.of<SentimentProvider>(context, listen: false)
                          .analyzeSentiment(pairs[index]);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.darkBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white24,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          pairs[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // ════════════════════════════════════════════════════════
            // Current Price & Change
            // ════════════════════════════════════════════════════════
            Consumer<ForexProvider>(
              builder: (context, forexProvider, child) {
                final pair = forexProvider.quotes[pairs[_currentPairIndex]];
                
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        pair?.mid.toStringAsFixed(5) ?? '1.10500',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            pair != null && pair.isUp
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: pair != null && pair.isUp
                                ? AppColors.bullish
                                : AppColors.bearish,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pair?.change.toStringAsFixed(2) ?? '0.00'}% '
                            '(${pair?.changeAmount.toStringAsFixed(4) ?? '0.0000'})',
                            style: TextStyle(
                              fontSize: 16,
                              color: pair != null && pair.isUp
                                  ? AppColors.bullish
                                  : AppColors.bearish,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            // ════════════════════════════════════════════════════════
            // Tab Navigation
            // ════════════════════════════════════════════════════════
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Chart'),
                Tab(text: 'Signals'),
                Tab(text: 'Sentiment'),
                Tab(text: 'Indicators'),
              ],
              indicatorColor: AppColors.primary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 3,
                ),
              ),
            ),
            // ════════════════════════════════════════════════════════
            // Tab Content
            // ════════════════════════════════════════════════════════
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Chart Tab
                  ChartWidget(pair: pairs[_currentPairIndex]),
                  
                  // Signals Tab
                  Consumer<SignalsProvider>(
                    builder: (context, signalsProvider, child) {
                      final signals = signalsProvider.signals
                          .where((s) => s.pair == pairs[_currentPairIndex])
                          .toList();

                      if (signals.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_neutral,
                                size: 64,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No signals yet',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: signals.length,
                        itemBuilder: (context, index) {
                          return SignalCard(signal: signals[index]);
                        },
                      );
                    },
                  ),
                  
                  // Sentiment Tab
                  Consumer<SentimentProvider>(
                    builder: (context, sentimentProvider, child) {
                      final sentiment =
                          sentimentProvider.sentiments[pairs[_currentPairIndex]];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (sentiment != null)
                              SentimentGauge(sentiment: sentiment),
                            const SizedBox(height: 24),
                            Text(
                              'Market News',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            // News list akan ditampilkan di sini
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Indicators Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technical Indicators',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        // Indicator cards akan ditampilkan di sini
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.darkCard,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: const Text(
                'Forex Analyzer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Watchlist'),
              onTap: () {
                // Navigate to watchlist
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Signal History'),
              onTap: () {
                // Navigate to history
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Economic Calendar'),
              onTap: () {
                // Navigate to calendar
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
    );
  }
}