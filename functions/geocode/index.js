const { Client, TablesDB } = require('node-appwrite');
const crypto = require('crypto');

const DATABASE_ID = 'singgah';
const HOURLY_LIMIT = 60;
const USER_AGENT =
  process.env.OSM_USER_AGENT ||
  'SinggahApp/1.0 (https://singgah.app; contact@singgah.app)';
const NOMINATIM = 'https://nominatim.openstreetmap.org';
let upstreamChain = Promise.resolve();

module.exports = async ({ req, res, log, error }) => {
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) return res.json({ error: 'not_authenticated' }, 401);

  let body = {};
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (_) {
    return res.json({ error: 'invalid_json' }, 400);
  }

  const mode = body?.mode === 'reverse' ? 'reverse' : 'search';
  const lang = body?.lang === 'en' ? 'en' : 'id';
  if (mode === 'search') {
    const q = String(body?.q ?? '').trim();
    if (q.length < 2 || q.length > 160) {
      return res.json({ error: 'invalid_query' }, 400);
    }
  } else {
    const lat = Number(body?.lat);
    const lon = Number(body?.lon);
    if (!Number.isFinite(lat) || !Number.isFinite(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return res.json({ error: 'invalid_coordinates' }, 400);
    }
  }

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT || process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const tables = new TablesDB(client);

  try {
    const allowed = await consumeQuota(tables, userId);
    if (!allowed.allowed) {
      return res.json({ error: 'rate_limited', reset_at: allowed.resetAt }, 429);
    }
  } catch (err) {
    error('quota failed: ' + err.message);
    return res.json({ error: 'quota_unavailable' }, 503);
  }

  const cacheKey = mode === 'search'
    ? `search|${lang}|${String(body?.q ?? '').trim().toLowerCase()}`
    : `reverse|${lang}|${Number(body?.lat).toFixed(5)}|${Number(body?.lon).toFixed(5)}`;
  const cacheId = crypto.createHash('sha256').update(cacheKey).digest('hex').slice(0, 32);

  try {
    const cached = await tables.getRow({
      databaseId: DATABASE_ID,
      tableId: 'geocode_cache',
      rowId: cacheId,
    });
    if (cached.expires_at && new Date(cached.expires_at).getTime() > Date.now()) {
      return res.json(JSON.parse(cached.payload));
    }
  } catch (err) {
    if (err.code !== 404) error('cache read failed: ' + err.message);
  }

  let result;
  try {
    result = await enqueue(() =>
      mode === 'reverse'
        ? reverse(Number(body.lat), Number(body.lon), lang)
        : search(String(body.q).trim(), lang),
    );
  } catch (err) {
    error('nominatim failed: ' + err.message);
    return res.json({ error: 'search_unavailable' }, 503);
  }

  const ttl = mode === 'reverse' ? 90 : 30;
  const now = new Date().toISOString();
  const expiresAt = new Date(Date.now() + ttl * 86400_000).toISOString();
  try {
    await tables.upsertRow({
      databaseId: DATABASE_ID,
      tableId: 'geocode_cache',
      rowId: cacheId,
      data: {
        cache_key: cacheKey,
        payload: JSON.stringify(result),
        created_at: now,
        expires_at: expiresAt,
      },
      permissions: [],
    });
  } catch (err) {
    error('cache write failed: ' + err.message);
  }
  return res.json(result);
};

async function consumeQuota(tables, userId) {
  const windowSeconds = 3600;
  const windowStart = Math.floor(Date.now() / 1000 / windowSeconds) * windowSeconds;
  const rowId = crypto
    .createHash('sha256')
    .update(`${userId}:geocode:${windowStart}`)
    .digest('hex')
    .slice(0, 32);
  const resetAt = new Date((windowStart + windowSeconds) * 1000).toISOString();
  try {
    const row = await tables.getRow({
      databaseId: DATABASE_ID,
      tableId: 'rate_limits',
      rowId,
    });
    if (row.count >= HOURLY_LIMIT) return { allowed: false, resetAt };
    await tables.updateRow({
      databaseId: DATABASE_ID,
      tableId: 'rate_limits',
      rowId,
      data: { count: row.count + 1 },
      permissions: [],
    });
    return { allowed: true, resetAt };
  } catch (err) {
    if (err.code === 404) {
      try {
        await tables.createRow({
          databaseId: DATABASE_ID,
          tableId: 'rate_limits',
          rowId,
          data: {
            user_id: userId,
            action: 'geocode',
            window_start: new Date(windowStart * 1000).toISOString(),
            count: 1,
          },
          permissions: [],
        });
        return { allowed: true, resetAt };
      } catch (_) {
        const row = await tables.getRow({
          databaseId: DATABASE_ID,
          tableId: 'rate_limits',
          rowId,
        });
        if (row.count >= HOURLY_LIMIT) return { allowed: false, resetAt };
        await tables.updateRow({
          databaseId: DATABASE_ID,
          tableId: 'rate_limits',
          rowId,
          data: { count: row.count + 1 },
          permissions: [],
        });
        return { allowed: true, resetAt };
      }
    }
    throw err;
  }
}

async function enqueue(task) {
  const run = upstreamChain.then(task, task);
  upstreamChain = run.then(() => undefined, () => undefined);
  return run;
}

async function search(query, lang) {
  const params = new URLSearchParams({
    format: 'jsonv2',
    addressdetails: '1',
    limit: '6',
    'accept-language': lang,
    q: query,
  });
  const response = await fetch(`${NOMINATIM}/search?${params}`, {
    headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' },
    signal: AbortSignal.timeout(12000),
  });
  if (!response.ok) throw new Error('Nominatim ' + response.status);
  const payload = await response.json();
  const rows = Array.isArray(payload) ? payload : [];
  return {
    results: rows
      .filter((row) => row && row.lat && row.lon)
      .map((row) => {
        const display = String(row.display_name ?? '');
        return {
          name: String(row.name ?? display.split(',')[0] ?? '').trim(),
          display_name: display,
          lat: Number(row.lat),
          lon: Number(row.lon),
          category: String(row.category ?? row.type ?? ''),
        };
      })
      .filter((row) => row.name.length > 0),
  };
}

async function reverse(lat, lon, lang) {
  const params = new URLSearchParams({
    format: 'jsonv2',
    addressdetails: '1',
    zoom: '18',
    'accept-language': lang,
    lat: String(lat),
    lon: String(lon),
  });
  const response = await fetch(`${NOMINATIM}/reverse?${params}`, {
    headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' },
    signal: AbortSignal.timeout(12000),
  });
  if (!response.ok) throw new Error('Nominatim ' + response.status);
  const row = await response.json();
  return { address: String(row?.display_name ?? '').trim() };
}

