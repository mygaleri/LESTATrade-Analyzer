// backend/server.js
// ════════════════════════════════════════════════════════════════════
// Forex Analyzer Backend Server
// Real-time data aggregation, signal generation, sentiment analysis
// ════════════════════════════════════════════════════════════════════

const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const dotenv = require('dotenv');
const axios = require('axios');

dotenv.config();

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(cors());
app.use(express.json());

// ════════════════════════════════════════════════════════════════════
// Configuration
// ════════════════════════════════════════════════════════════════════

const CONFIG = {
  BROKER_API_KEY: process.env.BROKER_API_KEY,
  FINNHUB_API_KEY: process.env.FINNHUB_API_KEY,
  NEWSAPI_API_KEY: process.env.NEWSAPI_API_KEY,
  PORT: process.env.PORT || 5000,
};

// Supported pairs
const FOREX_PAIRS = [
  'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF', 'AUD/USD',
  'USD/CAD', 'NZD/USD', 'EUR/GBP', 'EUR/JPY', 'GBP/JPY',
];

// Store data in memory (use Redis dalam production)
const dataStore = {
  quotes: {},
  signals: [],
  sentiments: {},
};

// ════════════════════════════════════════════════════════════════════
// Routes
// ════════════════════════════════════════════════════════════════════

// Get current quotes untuk semua pairs
app.get('/api/quotes', async (req, res) => {
  try {
    const quotes = Object.values(dataStore.quotes);
    res.json({
      success: true,
      data: quotes,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get quote untuk specific pair
app.get('/api/quotes/:pair', async (req, res) => {
  try {
    const pair = req.params.pair.toUpperCase();
    const quote = dataStore.quotes[pair];

    if (!quote) {
      return res.status(404).json({
        success: false,
        error: 'Pair not found',
      });
    }

    res.json({
      success: true,
      data: quote,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get candles (historical data)
app.get('/api/candles/:pair', async (req, res) => {
  try {
    const pair = req.params.pair.toUpperCase();
    const timeframe = req.query.timeframe || '1h';
    const limit = req.query.limit || 100;

    // Ambil dari broker API
    const candles = await getCandles(pair, timeframe, limit);

    res.json({
      success: true,
      pair: pair,
      timeframe: timeframe,
      data: candles,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get technical indicators
app.get('/api/indicators/:pair', async (req, res) => {
  try {
    const pair = req.params.pair.toUpperCase();
    const timeframe = req.query.timeframe || '1h';

    // Calculate indicators dari candles
    const candles = await getCandles(pair, timeframe, 200);
    const indicators = calculateIndicators(candles);

    res.json({
      success: true,
      pair: pair,
      data: indicators,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get trading signals
app.get('/api/signals', async (req, res) => {
  try {
    const pair = req.query.pair;
    let signals = dataStore.signals;

    if (pair) {
      signals = signals.filter(s => s.pair === pair.toUpperCase());
    }

    res.json({
      success: true,
      data: signals,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get sentiment analysis
app.get('/api/sentiment/:pair', async (req, res) => {
  try {
    const pair = req.params.pair.toUpperCase();
    const sentiment = dataStore.sentiments[pair] || null;

    if (!sentiment) {
      return res.status(404).json({
        success: false,
        error: 'No sentiment data available',
      });
    }

    res.json({
      success: true,
      data: sentiment,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get economic calendar
app.get('/api/economic-calendar', async (req, res) => {
  try {
    const countryCode = req.query.country || 'USD';
    const daysAhead = req.query.days || 7;

    const events = await getEconomicCalendar(countryCode, daysAhead);

    res.json({
      success: true,
      country: countryCode,
      data: events,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get news
app.get('/api/news/:pair', async (req, res) => {
  try {
    const pair = req.params.pair.toUpperCase();
    const limit = req.query.limit || 10;

    const news = await getNews(pair, limit);

    res.json({
      success: true,
      pair: pair,
      data: news,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// ════════════════════════════════════════════════════════════════════
// WebSocket untuk Real-time Updates
// ════════════════════════════════════════════════════════════════════

wss.on('connection', (ws) => {
  console.log('New WebSocket connection');

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);

      if (data.type === 'subscribe') {
        // Subscribe ke specific pair
        ws.subscribedPairs = ws.subscribedPairs || [];
        ws.subscribedPairs.push(data.pair.toUpperCase());
        console.log(`Client subscribed to ${data.pair}`);

        ws.send(JSON.stringify({
          type: 'subscribed',
          pair: data.pair.toUpperCase(),
          message: 'Successfully subscribed',
        }));
      }

      if (data.type === 'unsubscribe') {
        ws.subscribedPairs = ws.subscribedPairs || [];
        ws.subscribedPairs = ws.subscribedPairs.filter(
          p => p !== data.pair.toUpperCase()
        );
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  });

  ws.on('close', () => {
    console.log('WebSocket connection closed');
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

// Broadcast quote updates ke semua connected clients
function broadcastQuote(pair, quote) {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      const subscribedPairs = client.subscribedPairs || [];
      if (subscribedPairs.includes(pair)) {
        client.send(JSON.stringify({
          type: 'quote',
          pair: pair,
          data: quote,
          timestamp: new Date().toISOString(),
        }));
      }
    }
  });
}

// ════════════════════════════════════════════════════════════════════
// Data Fetching Functions
// ════════════════════════════════════════════════════════════════════

async function getCandles(pair, timeframe, limit) {
  try {
    // Implement broker API call
    // Contoh dengan mock data untuk development
    const candles = [];
    const basePrice = 1.1050;

    for (let i = limit; i > 0; i--) {
      const open = basePrice + (i * 0.0001);
      const close = open + (0.0005 * (i % 2 === 0 ? 1 : -1));
      const high = Math.max(open, close) + 0.001;
      const low = Math.min(open, close) - 0.001;

      candles.push({
        time: new Date(Date.now() - i * 3600000).toISOString(),
        open,
        high,
        low,
        close,
        volume: 1000000 + i * 10000,
      });
    }

    return candles;
  } catch (error) {
    console.error('Error getting candles:', error);
    return [];
  }
}

async function getNews(pair, limit) {
  try {
    const currencies = pair.split('/');
    const query = `${currencies[0]} ${currencies[1]} forex`;

    const response = await axios.get(
      'https://newsapi.org/v2/everything',
      {
        params: {
          q: query,
          sortBy: 'publishedAt',
          language: 'en',
          pageSize: limit,
          apiKey: CONFIG.NEWSAPI_API_KEY,
        },
      }
    );

    return response.data.articles.map(article => ({
      title: article.title,
      description: article.description,
      source: article.source.name,
      url: article.url,
      image: article.urlToImage,
      publishedAt: article.publishedAt,
    }));
  } catch (error) {
    console.error('Error fetching news:', error);
    return [];
  }
}

async function getEconomicCalendar(countryCode, daysAhead) {
  try {
    const response = await axios.get(
      'https://finnhub.io/api/v1/economic_calendar',
      {
        params: {
          token: CONFIG.FINNHUB_API_KEY,
        },
      }
    );

    const now = new Date();
    const futureDate = new Date(now.getTime() + daysAhead * 24 * 60 * 60 * 1000);

    return response.data
      .filter(event => {
        try {
          const eventTime = new Date(event.time);
          return (
            eventTime > now &&
            eventTime < futureDate &&
            event.country === countryCode
          );
        } catch (e) {
          return false;
        }
      })
      .map(event => ({
        event: event.event,
        country: event.country,
        impact: event.impact,
        forecast: event.forecast,
        previous: event.previous,
        actual: event.actual,
        time: event.time,
        unit: event.unit,
      }));
  } catch (error) {
    console.error('Error fetching economic calendar:', error);
    return [];
  }
}

// ════════════════════════════════════════════════════════════════════
// Technical Indicators Calculation
// ════════════════════════════════════════════════════════════════════

function calculateIndicators(candles) {
  if (candles.length === 0) return {};

  const closes = candles.map(c => c.close);

  return {
    rsi: calculateRSI(closes, 14),
    macd: calculateMACD(closes),
    bollingerBands: calculateBollingerBands(closes, 20),
    sma20: calculateSMA(closes, 20),
    sma50: calculateSMA(closes, 50),
    sma200: calculateSMA(closes, 200),
    stochastic: calculateStochastic(candles, 14),
    atr: calculateATR(candles, 14),
  };
}

function calculateRSI(prices, period) {
  if (prices.length < period + 1) return 50;

  let gains = 0,
    losses = 0;

  for (let i = 1; i <= period; i++) {
    const diff = prices[i] - prices[i - 1];
    if (diff > 0) gains += diff;
    else losses -= diff;
  }

  let avgGain = gains / period;
  let avgLoss = losses / period;

  for (let i = period + 1; i < prices.length; i++) {
    const diff = prices[i] - prices[i - 1];
    if (diff > 0) {
      avgGain = (avgGain * (period - 1) + diff) / period;
      avgLoss = (avgLoss * (period - 1)) / period;
    } else {
      avgGain = (avgGain * (period - 1)) / period;
      avgLoss = (avgLoss * (period - 1) + -diff) / period;
    }
  }

  const rs = avgGain / avgLoss;
  const rsi = 100 - 100 / (1 + rs);

  return Math.max(0, Math.min(100, rsi));
}

function calculateSMA(prices, period) {
  if (prices.length < period) return 0;

  let sum = 0;
  for (let i = 0; i < period; i++) {
    sum += prices[i];
  }
  return sum / period;
}

function calculateMACD(prices, fast = 12, slow = 26, signal = 9) {
  // Simplified MACD
  return {
    line: 0,
    signal: 0,
    histogram: 0,
  };
}

function calculateBollingerBands(prices, period) {
  const sma = calculateSMA(prices, period);

  let variance = 0;
  for (let i = 0; i < period; i++) {
    variance += Math.pow(prices[i] - sma, 2);
  }
  variance /= period;
  const stdDev = Math.sqrt(variance);

  return {
    upper: sma + 2 * stdDev,
    middle: sma,
    lower: sma - 2 * stdDev,
  };
}

function calculateStochastic(candles, period) {
  const recent = candles.slice(-period);
  const highs = recent.map(c => c.high);
  const lows = recent.map(c => c.low);

  const highest = Math.max(...highs);
  const lowest = Math.min(...lows);
  const current = candles[candles.length - 1].close;

  const k = ((current - lowest) / (highest - lowest)) * 100;
  return Math.max(0, Math.min(100, k));
}

function calculateATR(candles, period) {
  const tr = [];

  for (let i = 0; i < candles.length; i++) {
    let trValue;
    if (i === 0) {
      trValue = candles[i].high - candles[i].low;
    } else {
      const tr1 = candles[i].high - candles[i].low;
      const tr2 = Math.abs(candles[i].high - candles[i - 1].close);
      const tr3 = Math.abs(candles[i].low - candles[i - 1].close);
      trValue = Math.max(tr1, tr2, tr3);
    }
    tr.push(trValue);
  }

  let atr = 0;
  for (let i = 0; i < period; i++) {
    atr += tr[i];
  }
  atr /= period;

  return atr;
}

// ════════════════════════════════════════════════════════════════════
// Periodic Tasks
// ════════════════════════════════════════════════════════════════════

// Update quotes setiap 5 detik
setInterval(async () => {
  for (const pair of FOREX_PAIRS) {
    try {
      // Fetch quote dari broker API
      // Untuk demo, gunakan mock data
      const quote = {
        symbol: pair,
        bid: 1.1050 + Math.random() * 0.001,
        ask: 1.1052 + Math.random() * 0.001,
        change: Math.random() * 2 - 1,
        timestamp: new Date().toISOString(),
      };

      dataStore.quotes[pair] = quote;
      broadcastQuote(pair, quote);
    } catch (error) {
      console.error(`Error updating ${pair}:`, error);
    }
  }
}, 5000);

// Update sentiment setiap jam
setInterval(async () => {
  for (const pair of FOREX_PAIRS) {
    try {
      const news = await getNews(pair, 10);
      // Simplified sentiment calculation
      const sentiment = {
        pair: pair,
        score: Math.random() * 2 - 1, // -1 to 1
        newsCount: news.length,
        timestamp: new Date().toISOString(),
      };

      dataStore.sentiments[pair] = sentiment;
    } catch (error) {
      console.error(`Error updating sentiment for ${pair}:`, error);
    }
  }
}, 3600000); // 1 hour

// ════════════════════════════════════════════════════════════════════
// Start Server
// ════════════════════════════════════════════════════════════════════

server.listen(CONFIG.PORT, () => {
  console.log(`
╔════════════════════════════════════════╗
║   Forex Analyzer Server Started        ║
║   Port: ${CONFIG.PORT}                      ║
║   WebSocket: ws://localhost:${CONFIG.PORT}  ║
╚════════════════════════════════════════╝
  `);
});

module.exports = { app, wss };
