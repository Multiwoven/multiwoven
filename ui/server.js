const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

<<<<<<< HEAD
=======
const upstream = process.env.VITE_API_HOST;
if (!upstream) {
  throw new Error('VITE_API_HOST is required (e.g. https://api.staging.squared.ai)');
}

const FRAME_ANCESTORS_TTL_MS = 60_000;
const FRAME_ANCESTORS_LRU_MAX = 10_000;
const FRAME_ANCESTORS_LOOKUP_TIMEOUT_MS = 2_000;
const RENDER_DATA_APP_RE = /^\/render\/data-app(\/assistant)?$/;

// Simple insertion-order LRU using a Map — no external deps.
const originsCache = new Map();
const inflight = new Map();

const cacheGet = (key) => {
  if (!originsCache.has(key)) return null;
  const entry = originsCache.get(key);
  // Touch (re-insert) so the entry moves to the "newest" end.
  originsCache.delete(key);
  originsCache.set(key, entry);
  return entry;
};

const cacheSet = (key, value) => {
  if (originsCache.has(key)) originsCache.delete(key);
  originsCache.set(key, value);
  if (originsCache.size > FRAME_ANCESTORS_LRU_MAX) {
    // Drop the oldest.
    const first = originsCache.keys().next().value;
    if (first !== undefined) originsCache.delete(first);
  }
};

const fetchOrigins = (dataAppId) => {
  // Dedup concurrent misses for the same data-app.
  if (inflight.has(dataAppId)) return inflight.get(dataAppId);

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FRAME_ANCESTORS_LOOKUP_TIMEOUT_MS);

  const p = fetch(`${upstream}/enterprise/api/v1/embed_origins/lookup?data_app_id=${dataAppId}`,
                  { signal: controller.signal })
    .then((r) => (r.ok ? r.json() : { origins: [] }))
    .then((body) => Array.isArray(body?.origins) ? body.origins : [])
    .catch(() => [])
    .finally(() => {
      clearTimeout(timer);
      inflight.delete(dataAppId);
    });

  inflight.set(dataAppId, p);
  return p;
};

const composeFrameAncestors = (origins) =>
  `frame-ancestors ${["'self'", ...origins].join(' ')}`;

app.use(async (req, res, next) => {
  if (!RENDER_DATA_APP_RE.test(req.path)) {
    res.setHeader('Content-Security-Policy', "frame-ancestors 'self'");
    return next();
  }

  const url = new URL(req.url, `http://${req.headers.host}`);
  const dataAppId = url.searchParams.get('dataAppId');
  if (!dataAppId) {
    res.setHeader('Content-Security-Policy', "frame-ancestors 'self'");
    return next();
  }

  const now = Date.now();
  const cached = cacheGet(dataAppId);
  let origins;
  if (cached && now - cached.lastFetchedAt < FRAME_ANCESTORS_TTL_MS) {
    origins = cached.origins;
  } else {
    origins = await fetchOrigins(dataAppId);
    cacheSet(dataAppId, { origins, lastFetchedAt: Date.now() });
  }
  res.setHeader('Content-Security-Policy', composeFrameAncestors(origins));
  return next();
});

app.use(
  createProxyMiddleware({
    pathFilter: ['/api', '/enterprise', '/saml'],
    target: upstream,
    changeOrigin: true,
    xfwd: true,
  }),
);

>>>>>>> bb0ec6d75 (chore(CE): added clickjacking frame ancestors header for security (#2124))
// Serve static files from the React app build directory
app.use(express.static(path.join(__dirname, 'dist')));

app.get('/env', (req, res) => {
  res.json({
    VITE_API_HOST: process.env.VITE_API_HOST,
  });
});

// Handles any requests that don't match the ones above
app.get(/(.*)/, (req, res) => {
  const indexPath = path.join(__dirname, 'dist', 'index.html');
  fs.readFile(indexPath, 'utf8', (err, data) => {
    if (err) {
      console.error('Error reading the index.html file', err);
      return res.status(500).send('An error occurred serving the application');
    }
    // Replace the placeholder in the HTML with the actual environment variable
    data = data.replace(/__VITE_API_HOST__/g, process.env.VITE_API_HOST);
    res.send(data);
  });
});

const port = process.env.PORT || 8000;
app.listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});
