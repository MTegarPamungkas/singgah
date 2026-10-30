const {
  Client,
  TablesDB,
  Query,
  Permission,
  Role,
} = require('node-appwrite');
const crypto = require('crypto');

const MODELS = (process.env.GEMINI_MODEL || 'gemini-3.6-flash')
  .split(',')
  .map((model) => model.trim())
  .filter(Boolean);
const DAILY_LIMIT = 30;
const MAX_TEXT = 500;
const DATABASE_ID = 'singgah';

module.exports = async ({ req, res, log, error }) => {
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) return res.json({ error: 'not_authenticated' }, 401);

  let body = {};
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (_) {
    return res.json({ error: 'invalid_json' }, 400);
  }
  const text = String(body?.text ?? '').trim();
  const locale = body?.locale === 'en' ? 'en' : 'id';
  if (!text) return res.json({ error: 'text_required' }, 400);
  if (text.length > MAX_TEXT) return res.json({ error: 'too_long' }, 400);

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return res.json({ error: 'ai_unavailable' }, 503);

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT || process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const tables = new TablesDB(client);

  try {
    const allowed = await consumeQuota(tables, userId, 'parse-reminder', 86400, DAILY_LIMIT);
    if (!allowed.allowed) {
      return res.json(
        { error: 'rate_limited', reset_at: allowed.resetAt },
        429,
      );
    }
  } catch (err) {
    error('quota failed: ' + err.message);
    return res.json({ error: 'quota_unavailable' }, 503);
  }

  let response;
  let lastStatus = 0;
  for (const model of MODELS) {
    try {
      response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: JSON.stringify({
            contents: [
              { role: 'user', parts: [{ text: buildPrompt(text, locale) }] },
            ],
            generationConfig: {
              temperature: 0.2,
              maxOutputTokens: 1024,
            },
          }),
          signal: AbortSignal.timeout(15000),
        },
      );
    } catch (err) {
      error(`gemini ${model} request failed: ` + err.message);
      lastStatus = 503;
      continue;
    }

    if (response.ok) break;

    lastStatus = response.status;
    log(`gemini ${model} status ${response.status}`);
    // Capacity and quota errors are worth retrying on the next model.
    if (response.status !== 429 && response.status !== 503) break;
  }

  if (!response || !response.ok) {
    error('gemini unavailable after fallbacks, last status ' + lastStatus);
    return res.json(
      { error: 'ai_unavailable' },
      lastStatus === 429 ? 429 : 503,
    );
  }
  const payload = await response.json();
  const raw = (payload?.candidates?.[0]?.content?.parts ?? [])
    .map((part) => part?.text ?? '')
    .join('');
  const draft = raw ? normaliseDraft(raw, text) : null;
  if (!draft) {
    log('invalid draft: ' + raw.slice(0, 300));
    return res.json({ error: 'invalid_draft' }, 503);
  }
  return res.json({ draft });
};

async function consumeQuota(tables, userId, action, windowSeconds, limit) {
  const windowStart = Math.floor(Date.now() / 1000 / windowSeconds) * windowSeconds;
  const rowId = crypto
    .createHash('sha256')
    .update(`${userId}:${action}:${windowStart}`)
    .digest('hex')
    .slice(0, 32);
  const resetAt = new Date((windowStart + windowSeconds) * 1000).toISOString();
  try {
    const row = await tables.getRow({
      databaseId: DATABASE_ID,
      tableId: 'rate_limits',
      rowId,
    });
    if (row.count >= limit) return { allowed: false, resetAt };
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
            action,
            window_start: new Date(windowStart * 1000).toISOString(),
            count: 1,
          },
          permissions: [],
        });
        return { allowed: true, resetAt };
      } catch (_) {
        // Another request in the same window won the create race. Re-read and
        // increment instead of failing the whole AI call.
        const row = await tables.getRow({
          databaseId: DATABASE_ID,
          tableId: 'rate_limits',
          rowId,
        });
        if (row.count >= limit) return { allowed: false, resetAt };
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

function buildPrompt(text, locale) {
  const language = locale === 'en' ? 'English' : 'Indonesian';
  return `You turn one short ${language} sentence into a place reminder.
Respond with a single JSON object and nothing else (no markdown fences).

Keys:
- title: string, a short imperative task, without the reminder lead-in.
- place_name: string, only a place explicitly mentioned. Never invent one. Empty if unknown.
- trigger: "arrive" or "leave".
- repeat_days: array of ISO weekdays 1=Monday..7=Sunday. Empty array means every day.
- window_start, window_end: "HH:mm", 24-hour. Use "00:00" and "23:59" if no time.
- confidence: number 0..1.
- address: string, only if present, otherwise empty.
- note: string, extra detail or empty.

Sentence:
${JSON.stringify(text)}`;
}

function normaliseDraft(raw, text) {
  let parsed;
  try {
    const cleaned = raw
      .replace(/```json/gi, '')
      .replace(/```/g, '')
      .trim();
    // Models sometimes prepend reasoning; keep the outermost JSON object.
    const start = cleaned.indexOf('{');
    const end = cleaned.lastIndexOf('}');
    const json = start >= 0 && end > start ? cleaned.slice(start, end + 1) : cleaned;
    parsed = JSON.parse(json);
  } catch (parseError) {
    console.error('draft parse failed: ' + parseError.message + ' :: ' + raw.slice(0, 600));
    return null;
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return null;
  const title = asString(parsed.title).trim();
  if (!title) return null;
  const days = Array.isArray(parsed.repeat_days)
    ? [...new Set(parsed.repeat_days
      .map((day) => Number(day))
      .filter((day) => Number.isInteger(day) && day >= 1 && day <= 7))]
      .sort((a, b) => a - b)
    : [];
  return {
    title: title.slice(0, 140),
    place_name: asString(parsed.place_name).trim().slice(0, 140),
    trigger: asString(parsed.trigger).toLowerCase() === 'leave' ? 'leave' : 'arrive',
    repeat_days: days,
    window_start: asClock(parsed.window_start, '00:00'),
    window_end: asClock(parsed.window_end, '23:59'),
    confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0.5)),
    address: asString(parsed.address).trim().slice(0, 240),
    note: asString(parsed.note).trim().slice(0, 500),
    raw_text: text,
  };
}

function asString(value) {
  return typeof value === 'string' ? value : '';
}

function asClock(value, fallback) {
  const match = /^(\d{1,2}):(\d{2})$/.exec(asString(value).trim());
  if (!match) return fallback;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  if (hour > 23 || minute > 59) return fallback;
  return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
}


