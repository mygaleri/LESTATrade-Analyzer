╔════════════════════════════════════════════════════════════════════════════════╗
║                    FOREX ANALYZER - COMPLETE SETUP GUIDE                       ║
║                  Real-time Analysis, Signals, Sentiment Android App            ║
╚════════════════════════════════════════════════════════════════════════════════╝

## 📋 TABLE OF CONTENTS

1. Project Overview
2. System Architecture
3. Prerequisites
4. Backend Setup (Node.js)
5. Frontend Setup (Flutter)
6. API Configuration
7. Features Explanation
8. Deployment Guide
9. Testing Guide
10. Troubleshooting

═════════════════════════════════════════════════════════════════════════════════

## 1️⃣ PROJECT OVERVIEW

Forex Analyzer adalah aplikasi Android real-time untuk analisis forex dengan:

✅ Real-time Price Quotes & Charts (Candlestick)
✅ Technical Analysis (RSI, MACD, Bollinger Bands, MA)
✅ Automated Trading Signals (Buy/Sell dengan confidence score)
✅ Sentiment Analysis dari berita & social media
✅ Economic Calendar dengan countdown
✅ Multi-timeframe Analysis
✅ Risk Management Tools (TP/SL calculation)
✅ Watchlist & Signal History
✅ Push Notifications untuk signals

### Tech Stack:
- **Frontend**: Flutter (Dart) - Cross-platform Android/iOS
- **Backend**: Node.js + Express
- **Database**: Hive (Local), Firebase (Cloud)
- **Real-time**: WebSocket + REST API
- **Charts**: fl_chart, syncfusion
- **State Management**: Provider pattern

═════════════════════════════════════════════════════════════════════════════════

## 2️⃣ SYSTEM ARCHITECTURE

┌─────────────────────────────────────────────────────────────────────────┐
│                           USER INTERFACE (Flutter)                       │
│  - Home Screen (Charts & Current Prices)                                 │
│  - Signals Screen (Buy/Sell Recommendations)                             │
│  - Sentiment Screen (Market Analysis)                                    │
│  - Economic Calendar (Upcoming Events)                                   │
│  - Watchlist (Tracked Pairs)                                             │
└────────────────────────┬────────────────────────────────────────────────┘
                         │ HTTP REST API + WebSocket
┌────────────────────────▼────────────────────────────────────────────────┐
│                      BACKEND SERVICE (Node.js)                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ API Routes:                                                       │  │
│  │ - /api/quotes/:pair          - Real-time forex quotes           │  │
│  │ - /api/candles/:pair         - Historical price data            │  │
│  │ - /api/indicators/:pair      - Technical indicators             │  │
│  │ - /api/signals               - Trading signals                  │  │
│  │ - /api/sentiment/:pair       - Market sentiment                 │  │
│  │ - /api/news/:pair            - Latest news                      │  │
│  │ - /api/economic-calendar     - Economic events                  │  │
│  │ - WebSocket (/ws)            - Real-time price streaming        │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Services:                                                         │  │
│  │ - Broker API Integration (MT5, Oanda, IB)                       │  │
│  │ - Technical Indicators Calculator                                │  │
│  │ - Signal Generator                                               │  │
│  │ - News & Sentiment Analyzer                                     │  │
│  │ - Economic Calendar Fetcher                                     │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────┬───────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼───┐    ┌─────▼──────┐  ┌────▼───────┐
    │ Broker │    │   News &   │  │  Economic  │
    │  APIs  │    │ Sentiment  │  │  Calendar  │
    │        │    │   APIs     │  │   APIs     │
    ├────────┤    ├────────────┤  ├────────────┤
    │ MT5    │    │ Finnhub    │  │ Finnhub    │
    │ Oanda  │    │ NewsAPI    │  │ Forex      │
    │ IB     │    │ Twitter    │  │ Factory    │
    └────────┘    └────────────┘  └────────────┘

═════════════════════════════════════════════════════════════════════════════════

## 3️⃣ PREREQUISITES

### Untuk Development:

#### Hardware & OS:
- Windows/Mac/Linux dengan 8GB+ RAM
- Android phone/emulator (Android 10+) untuk testing

#### Software:
1. **Flutter SDK** (v3.0+)
   - Download dari https://flutter.dev/docs/get-started/install
   - Set PATH: export PATH="$PATH:~/flutter/bin"
   - Verify: flutter --version

2. **Node.js & npm** (v16+)
   - Download dari https://nodejs.org/
   - Verify: node --version && npm --version

3. **Git**
   - Download dari https://git-scm.com/

4. **Android Studio** (untuk Flutter development)
   - Download dari https://developer.android.com/studio
   - Install Android SDK 32+, NDK
   - Set ANDROID_HOME environment variable

#### API Keys (Gratis/Trial):
1. **Finnhub API Key**
   - Sign up: https://finnhub.io
   - Get free API key untuk 60 API calls/minute

2. **NewsAPI Key**
   - Sign up: https://newsapi.org
   - Free tier: 100 requests/day

3. **Broker API Credentials**
   - MetaTrader 5: https://www.metatrader5.com
   - Oanda: https://developer.oanda.com (demo account)
   - Interactive Brokers: https://www.interactivebrokers.com

═════════════════════════════════════════════════════════════════════════════════

## 4️⃣ BACKEND SETUP (Node.js)

### Step 1: Initialize Backend Project

```bash
# Create project directory
mkdir forex-analyzer
cd forex-analyzer

# Create backend folder
mkdir backend
cd backend

# Initialize npm
npm init -y

# Install dependencies
npm install express ws cors dotenv axios moment redis mongoose nodemon
npm install --save-dev jest eslint
```

### Step 2: Create Project Structure

```bash
mkdir -p {routes,controllers,services,config,utils,middleware}
touch server.js .env .env.example
```

### Step 3: Setup Environment Variables

```bash
# Copy .env.example ke .env dan isi credentials Anda
cp .env.example .env

# Edit .env dengan text editor
# Masukkan API keys dari langkah prerequisites
```

### Step 4: Create Core Files

```bash
# Copy file-file dari yang sudah saya buat:
# - server.js (sudah ada di atas)
# - routes/
# - controllers/
# - services/

# Run development server
npm run dev

# Output:
# ╔════════════════════════════════════════╗
# ║   Forex Analyzer Server Started        ║
# ║   Port: 5000                           ║
# ║   WebSocket: ws://localhost:5000       ║
# ╚════════════════════════════════════════╝
```

### Step 5: Test Backend APIs

```bash
# Test endpoints
curl http://localhost:5000/health
# Response: {"status":"OK","timestamp":"...","uptime":...}

curl http://localhost:5000/api/quotes
# Response: {"success":true,"data":[...],"timestamp":"..."}

# Test WebSocket dengan wscat
npm install -g wscat
wscat -c ws://localhost:5000
# Connected, sekarang bisa send message
```

═════════════════════════════════════════════════════════════════════════════════

## 5️⃣ FRONTEND SETUP (Flutter)

### Step 1: Create Flutter Project

```bash
# Create Flutter app
flutter create forex_analyzer

cd forex_analyzer

# Check setup
flutter doctor
# Semua harus ✓ untuk development
```

### Step 2: Add Dependencies

```bash
# Edit pubspec.yaml dengan dependencies yang sudah saya buat
# Lalu run:

flutter pub get
```

### Step 3: Create Project Structure

```bash
# Dalam lib/ folder:
mkdir -p {models,services,providers,screens,widgets,utils}

# Copy file-file yang sudah saya buat:
# - main.dart (main entry point)
# - models/ (all model files)
# - services/ (API & indicator services)
# - providers/ (state management)
# - screens/ (UI screens)
# - widgets/ (reusable widgets)
# - utils/ (helpers & constants)
```

### Step 4: Configure Backend Connection

```dart
// lib/utils/constants.dart - Update baseURL

// Development (untuk testing di localhost)
static const String baseURL = 'http://10.0.2.2:5000'; // Android Emulator
// atau
static const String baseURL = 'http://192.168.x.x:5000'; // Real device (ganti dengan IP)
static const String webSocketURL = 'ws://10.0.2.2:5000';

// Production
// static const String baseURL = 'https://api.forexanalyzer.com';
```

### Step 5: Run Application

```bash
# Run di Android emulator
flutter emulators --launch Pixel_5_API_31

# Run app
flutter run

# Atau run specific device
flutter run -d emulator-5554

# Build APK untuk distribution
flutter build apk --release
```

═════════════════════════════════════════════════════════════════════════════════

## 6️⃣ API CONFIGURATION

### Broker API Setup

#### MetaTrader 5 Integration
```dart
// Untuk MT5, gunakan REST API wrapper atau WebAPI
// Documentation: https://www.metatrader5.com/en/api

BrokerAPI brokerAPI = BrokerAPI(
  brokerType: BrokerType.metatrader5,
  apiKey: 'your_mt5_api_key',
  accountNumber: '123456',
);
```

#### Oanda Integration (Recommended untuk Testing)
```dart
// Oanda punya sandbox untuk testing tanpa modal
// Sign up: https://developer.oanda.com
// Get demo account dengan virtual money

BrokerAPI brokerAPI = BrokerAPI(
  brokerType: BrokerType.oanda,
  apiKey: 'your_oanda_api_key',
  accountNumber: 'your_account_id',
);

// Example: Get EUR/USD quote
ForexPair? eurUsd = await brokerAPI.getQuote('EUR/USD');
print(eurUsd?.bid); // 1.10500
print(eurUsd?.ask); // 1.10502
```

#### Interactive Brokers Setup
```dart
BrokerAPI brokerAPI = BrokerAPI(
  brokerType: BrokerType.interactiveBrokers,
  apiKey: 'your_ib_api_key',
  accountNumber: 'your_account',
);
```

### News & Sentiment APIs

```dart
// Finnhub (recommended, free tier cukup)
NewsAPI newsAPI = NewsAPI(
  source: NewsSource.finnhub,
  apiKey: 'your_finnhub_api_key',
);

// NewsAPI (untuk berita umum)
NewsAPI newsAPI2 = NewsAPI(
  source: NewsSource.newsapi,
  apiKey: 'your_newsapi_key',
);

// Get news
List<Map> news = await newsAPI.getNews(pair: 'EUR/USD', limit: 10);

// Analyze sentiment
Sentiment sentiment = await newsAPI.analyzeSentiment(
  pair: 'EUR/USD',
  newsItems: news,
);
print('Sentiment: ${sentiment.scoreValue}'); // -1.0 to 1.0
```

═════════════════════════════════════════════════════════════════════════════════

## 7️⃣ FEATURES EXPLANATION

### A. Real-time Quotes & Charts

```dart
// Listen to real-time quotes
Provider.of<ForexProvider>(context, listen: false)
    .startRealTimeUpdates();

// Chart dengan candlestick
ChartWidget(pair: 'EUR/USD')

// Timeframes: 1m, 5m, 15m, 30m, 1h, 4h, 1d, 1w
```

### B. Technical Indicators

**RSI (Relative Strength Index)**
- Range: 0-100
- Overbought: > 70 (potential sell)
- Oversold: < 30 (potential buy)
- Neutral: 40-60

```dart
double rsi = TechnicalIndicators.calculateRSI(
  prices: closePrices,
  period: 14,
);
```

**MACD (Moving Average Convergence Divergence)**
- Signal bullish ketika MACD > Signal line (golden cross)
- Signal bearish ketika MACD < Signal line (death cross)

```dart
Map<String, double> macd = TechnicalIndicators.calculateMACD(
  prices: closePrices,
  fastPeriod: 12,
  slowPeriod: 26,
  signalPeriod: 9,
);
```

**Bollinger Bands**
- Price mendekati upper band: overbought
- Price mendekati lower band: oversold

```dart
Map<String, double> bb = TechnicalIndicators.calculateBollingerBands(
  prices: closePrices,
  period: 20,
  stdDevMultiplier: 2,
);
// Returns: {upper, middle, lower}
```

**Moving Averages**
- SMA 20, 50, 200 untuk trend confirmation
- Bullish trend: Price > SMA 50 > SMA 200

### C. Trading Signals Generation

Signal dihasilkan dari kombinasi multiple indicators:

```dart
Signal? signal = SignalGenerator.generateSignal(
  pair: 'EUR/USD',
  candles: candles,
  indicators: indicatorValues,
  currentPrice: 1.1050,
);

// Signal properties:
// - Type: buy, sell, strongBuy, strongSell, hold
// - Confidence: 0-100 (higher = more reliable)
// - Strength: number of indicators confirming
// - TP/SL: automatically calculated
```

**Signal Strength Classifications:**
- **Strong Signal**: 3+ indicators agree (confidence 80+%)
- **Normal Signal**: 1-2 indicators agree (confidence 60-80%)
- **Weak Signal**: Single indicator (confidence <60%)

### D. Sentiment Analysis

Market sentiment dari multiple sources:

```dart
// Get sentiment score (0-100)
double sentimentScore = await newsAPI.getMarketSentimentScore('EUR/USD');
// 0-30: Very Bearish
// 30-45: Bearish
// 45-55: Neutral
// 55-70: Bullish
// 70-100: Very Bullish
```

### E. Economic Calendar

```dart
// Get upcoming economic events
List<EconomicEvent> events = 
    await economicProvider.getEconomicCalendar(
  countryCode: 'USD',
  daysAhead: 7,
);

// High impact events yang perlu diperhatikan
List<EconomicEvent> highImpact = 
    economicProvider.getHighImpactEvents();
```

### F. Risk Management

```dart
// Auto-calculate Take Profit & Stop Loss
double tp = SignalGenerator.calculateTakeProfit(
  entryPrice: 1.1050,
  atr: 0.0050,
  isLong: true,
  atrMultiplier: 3.0, // Risk:Reward = 1:3
);

double sl = SignalGenerator.calculateStopLoss(
  entryPrice: 1.1050,
  atr: 0.0050,
  isLong: true,
  atrMultiplier: 1.5,
);

// Risk:Reward Ratio
double rr = IndicatorCalculations.calculateRiskReward(
  entryPrice: 1.1050,
  stopLoss: 1.1000,
  takeProfit: 1.1100,
); // Returns 2:1 (reward 2x risk)
```

═════════════════════════════════════════════════════════════════════════════════

## 8️⃣ DEPLOYMENT GUIDE

### Backend Deployment (Heroku/Railway)

```bash
# Heroku (free tier discontinued, use Railway/Render)
# Railway: https://railway.app

# 1. Push kode ke GitHub
git init
git add .
git commit -m "Initial commit"
git push origin main

# 2. Connect ke Railway
# - Login di railway.app
# - Create new project
# - Select GitHub repo
# - Railway auto-deploy setiap push

# 3. Set environment variables di Railway dashboard
# PORT, API keys, dll

# 4. Akses API di: https://your-app.up.railway.app/api/quotes
```

### Frontend Deployment (Google Play Store)

```bash
# 1. Create release APK/AAB
flutter build appbundle --release

# 2. Sign dengan keystore
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 3. Create app di Google Play Console
# - https://play.google.com/console
# - Create new app
# - Fill app information

# 4. Upload AAB ke Google Play Console
# - Navigate to Release > Production
# - Upload appbundle

# 5. Fill app details & submit untuk review
# - Min 24 jam untuk review

# Build size: ~50-60MB (dengan dependencies)
```

═════════════════════════════════════════════════════════════════════════════════

## 9️⃣ TESTING GUIDE

### Backend Testing

```bash
# Run unit tests
npm test

# Run dengan coverage
npm test -- --coverage

# Test specific endpoint
curl -X GET http://localhost:5000/api/quotes/EUR%2FUSD

# Load testing
npm install -g artillery
artillery quick --count 100 --num 10 \
  http://localhost:5000/api/quotes
```

### Frontend Testing

```bash
# Run widget tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Test di Android emulator
flutter emulators --launch Pixel_5_API_31
flutter run

# Manual testing checklist:
# ✓ Real-time quotes update
# ✓ Charts load correctly
# ✓ Signals generate dengan correct confidence
# ✓ Sentiment updates setiap jam
# ✓ WebSocket connection stable
# ✓ Local storage (watchlist) persists
# ✓ Notifications working
```

═════════════════════════════════════════════════════════════════════════════════

## 🔟 TROUBLESHOOTING

### Common Issues

**1. Backend tidak konek ke API broker**
```
Solution:
- Check API key validity
- Verify firewall settings
- Use mock data untuk testing (BrokerType.mockData)
```

**2. Flutter error: "Connection refused"**
```bash
# Emulator tidak bisa reach localhost:5000
# Solution:

# Untuk Android Emulator:
flutter run --dart-define=API_URL=http://10.0.2.2:5000

# Untuk real device:
# Ganti dengan IP address machine Anda
ipconfig getifaddr en0  # Mac/Linux
ipconfig /all           # Windows
```

**3. WebSocket connection timeout**
```
Solution:
- Check firewall allowing WebSocket (port 5000)
- Verify backend running: curl http://localhost:5000/health
- Try increase timeout di client
```

**4. News API rate limit exceeded**
```
Solution:
- Subscribe to paid plan
- Implement request caching
- Use multiple API keys rotating
- Increase interval antara requests
```

**5. Chart tidak muncul**
```dart
// Ensure candles data exists
if (candles.isEmpty) {
  return Center(child: CircularProgressIndicator());
}

// Debug: print data
debugPrint('Candles: ${candles.length}');
```

### Performance Optimization

```dart
// 1. Implement caching
final box = Hive.box('quotes');
final cachedQuote = box.get('EUR/USD');

// 2. Reduce update frequency
const quoteUpdateInterval = Duration(seconds: 5);

// 3. Use lazy loading untuk charts
const candleCount = 100; // Jangan load 1000+

// 4. Profile app
flutter run --profile

// 5. Use APK analyzer untuk size
android/build/outputs/apk/release/app-release.apk
```

═════════════════════════════════════════════════════════════════════════════════

## 📚 RESOURCES & REFERENCES

### Documentation
- Flutter: https://flutter.dev/docs
- Node.js/Express: https://expressjs.com/
- Technical Analysis: https://www.investopedia.com

### APIs
- Finnhub: https://finnhub.io/docs/api
- NewsAPI: https://newsapi.org/docs
- Oanda: https://developer.oanda.com/rest-live-v20/
- MetaTrader 5: https://www.metatrader5.com/en/documentation

### Libraries
- fl_chart: https://pub.dev/packages/fl_chart
- provider: https://pub.dev/packages/provider
- Hive: https://pub.dev/packages/hive

### Communities
- Stack Overflow: Tag dengan [flutter] [forex] [websocket]
- Reddit: r/FlutterDev, r/Forex
- GitHub: Discussions di repo

═════════════════════════════════════════════════════════════════════════════════

## ⚠️ DISCLAIMER

🚨 **IMPORTANT**: Aplikasi ini adalah EDUCATIONAL PURPOSE ONLY
- Bukan financial/investment advice
- Signals bukan guaranteed profit
- Always use proper risk management
- Paper trade dulu sebelum live trading
- Consult financial advisor sebelum trading real money

═════════════════════════════════════════════════════════════════════════════════

Selamat! Setup sudah lengkap. Mulai development dengan:

1. Terminal 1: cd backend && npm run dev
2. Terminal 2: cd forex_analyzer && flutter run
3. Akses di: http://localhost:5000 (backend) dan app

Good luck! 🚀📈
