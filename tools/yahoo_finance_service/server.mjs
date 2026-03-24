/**
 * Mini HTTP servis: yahoo-finance2 ile USD/TRY, EUR/TRY ve gram altın (TRY).
 * Altın: GC=F (USD/troy ons) × USDTRY ÷ 31.1034768 g/oz.
 *
 * Uyarı: Yahoo Finance verisi resmi değildir; kullanım koşulları ve rate limit geçerlidir.
 */
import cors from 'cors';
import express from 'express';
import YahooFinance from 'yahoo-finance2';

const PORT = Number(process.env.PORT || 8787);
const API_KEY = process.env.API_KEY?.trim();
const TROY_OZ_GRAMS = 31.1034768;

const yahooFinance = new YahooFinance({
  suppressNotices: ['yahooSurvey'],
});

function priceFromQuote(q) {
  const n =
    q?.regularMarketPrice ?? q?.postMarketPrice ?? q?.preMarketPrice ?? null;
  return typeof n === 'number' && !Number.isNaN(n) ? n : 0;
}

const app = express();
app.use(express.json({ limit: '32kb' }));
app.use(
  cors({
    origin: process.env.CORS_ORIGIN === '*' ? true : process.env.CORS_ORIGIN ?? true,
    credentials: false,
  }),
);

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'emlakmaster-yahoo-finance',
    ts: new Date().toISOString(),
  });
});

function requireApiKey(req, res, next) {
  if (!API_KEY) return next();
  const k = req.headers['x-api-key'];
  if (k !== API_KEY) {
    return res.status(401).json({ ok: false, error: 'Unauthorized' });
  }
  return next();
}

app.get('/rates', requireApiKey, async (_req, res) => {
  try {
    const quotes = await yahooFinance.quote(['USDTRY=X', 'EURTRY=X', 'GC=F']);
    const list = Array.isArray(quotes) ? quotes : [quotes];

    const bySymbol = new Map(list.map((q) => [q.symbol, q]));
    const usdQ = bySymbol.get('USDTRY=X');
    const eurQ = bySymbol.get('EURTRY=X');
    const gcQ = bySymbol.get('GC=F');

    const usdTry = priceFromQuote(usdQ);
    const eurTry = priceFromQuote(eurQ);
    const usdPerOz = priceFromQuote(gcQ);

    const gramGoldTry =
      usdPerOz > 0 && usdTry > 0 ? (usdPerOz * usdTry) / TROY_OZ_GRAMS : 0;

    const updatedAt = new Date().toISOString();

    res.json({
      ok: true,
      source: 'yahoo-finance2',
      usdTry,
      eurTry,
      gramGoldTry,
      symbols: {
        usd: 'USDTRY=X',
        eur: 'EURTRY=X',
        goldUsdPerTroyOz: 'GC=F',
      },
      updatedAt,
    });
  } catch (err) {
    console.error('[rates]', err);
    res.status(502).json({
      ok: false,
      error: String(err?.message ?? err),
    });
  }
});

app.listen(PORT, () => {
  console.log(
    `[yahoo_finance_service] http://127.0.0.1:${PORT}/rates (API_KEY: ${API_KEY ? 'on' : 'off'})`,
  );
});
