import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import type { Connect } from 'vite';
import type { IncomingMessage, ServerResponse } from 'http';

const FRAME_ANCESTORS_TTL_MS = 60_000;
const FRAME_ANCESTORS_LRU_MAX = 10_000;
const FRAME_ANCESTORS_LOOKUP_TIMEOUT_MS = 2_000;
const RENDER_DATA_APP_RE = /^\/render\/data-app(\/assistant)?$/;
const SELF_ONLY = "frame-ancestors 'self'";
const CSP_HEADER = 'Content-Security-Policy';

type CacheEntry = { origins: string[]; lastFetchedAt: number };
type OriginsCache = Map<string, CacheEntry>;
type InflightMap = Map<string, Promise<string[]>>;

const cacheGet = (cache: OriginsCache, key: string): CacheEntry | null => {
  const entry = cache.get(key);
  if (!entry) return null;
  // Touch: re-insert so this key moves to the newest end for LRU.
  cache.delete(key);
  cache.set(key, entry);
  return entry;
};

const cacheSet = (cache: OriginsCache, key: string, value: CacheEntry): void => {
  cache.delete(key);
  cache.set(key, value);
  if (cache.size > FRAME_ANCESTORS_LRU_MAX) {
    const oldest = cache.keys().next().value;
    if (oldest !== undefined) cache.delete(oldest);
  }
};

const readOrigins = (body: unknown): string[] => {
  const origins = (body as { origins?: unknown } | null)?.origins;
  return Array.isArray(origins) ? (origins as string[]) : [];
};

const fetchOrigins = (
  upstream: string,
  inflight: InflightMap,
  dataAppId: string,
): Promise<string[]> => {
  const existing = inflight.get(dataAppId);
  if (existing) return existing;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FRAME_ANCESTORS_LOOKUP_TIMEOUT_MS);

  const p = fetch(`${upstream}/enterprise/api/v1/embed_origins/lookup?data_app_id=${dataAppId}`,
                  { signal: controller.signal })
    .then((r) => (r.ok ? r.json() : { origins: [] }))
    .then(readOrigins)
    .catch(() => [])
    .finally(() => {
      clearTimeout(timer);
      inflight.delete(dataAppId);
    });

  inflight.set(dataAppId, p);
  return p;
};

const composeFrameAncestors = (origins: string[]): string =>
  `frame-ancestors ${["'self'", ...origins].join(' ')}`;

const resolveDataAppId = (req: IncomingMessage): string | null => {
  const url = new URL(req.url || '/', `http://${req.headers.host}`);
  return url.searchParams.get('dataAppId');
};

const isRenderDataAppPath = (rawUrl: string | undefined): boolean =>
  RENDER_DATA_APP_RE.test((rawUrl || '/').split('?')[0]);

const resolveOriginsFor = async (
  cache: OriginsCache,
  inflight: InflightMap,
  upstream: string,
  dataAppId: string,
): Promise<string[]> => {
  const cached = cacheGet(cache, dataAppId);
  if (cached && Date.now() - cached.lastFetchedAt < FRAME_ANCESTORS_TTL_MS) {
    return cached.origins;
  }
  const origins = await fetchOrigins(upstream, inflight, dataAppId);
  cacheSet(cache, dataAppId, { origins, lastFetchedAt: Date.now() });
  return origins;
};

const buildSecurityHeadersMiddleware = (upstream: string): Connect.NextHandleFunction => {
  const cache: OriginsCache = new Map();
  const inflight: InflightMap = new Map();

  return async (req: IncomingMessage, res: ServerResponse, next: Connect.NextFunction) => {
    if (!isRenderDataAppPath(req.url)) {
      res.setHeader(CSP_HEADER, SELF_ONLY);
      return next();
    }
    const dataAppId = resolveDataAppId(req);
    if (!dataAppId) {
      res.setHeader(CSP_HEADER, SELF_ONLY);
      return next();
    }
    const origins = await resolveOriginsFor(cache, inflight, upstream, dataAppId);
    res.setHeader(CSP_HEADER, composeFrameAncestors(origins));
    return next();
  };
};

// https://vitejs.dev/config/
<<<<<<< HEAD
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: [{ find: '@', replacement: '/src' }],
  },
  server: {
    port: 8000,
  },
=======
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const upstream = env.VITE_API_HOST || 'http://localhost:3000';
  return {
    plugins: [
      react(),
      {
        name: 'security-headers-middleware',
        configureServer(server) {
          server.middlewares.use(buildSecurityHeadersMiddleware(upstream));
        },
      },
    ],
    resolve: {
      alias: [{ find: '@', replacement: '/src' }],
    },
    server: {
      port: 8000,
      proxy: {
        '/api': { target: upstream, changeOrigin: true },
        // Forward the AppGen ActionCable connection.
        '/enterprise': {
          target: upstream,
          changeOrigin: true,
          ws: true,
          rewriteWsOrigin: true,
        },
        '/saml': { target: upstream, changeOrigin: true },
      },
    },
  };
>>>>>>> 26ac41b53 (chore(CE): clickjacking issue solved (#2128))
});
