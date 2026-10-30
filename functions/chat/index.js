const {
  Client,
  TablesDB,
  Query,
  Permission,
  Role,
} = require('node-appwrite');
const crypto = require('crypto');

const DATABASE_ID = 'singgah';
const FRIENDS = 'friendships';
const GROUPS = 'groups';
const MESSAGES = 'messages';

module.exports = async ({ req, res, log, error }) => {
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) return res.json({ error: 'not_authenticated' }, 401);

  let body = {};
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (_) {
    return res.json({ error: 'invalid_json' }, 400);
  }

  const conversationId = String(body.conversationId ?? '').trim();
  const text = String(body.body ?? '').trim();
  const participantIds = Array.isArray(body.participantIds)
    ? body.participantIds.map((id) => String(id))
    : [];
  if (!conversationId) return res.json({ error: 'conversation_required' }, 400);
  if (!text) return res.json({ error: 'message_required' }, 400);
  if (text.length > 2000) return res.json({ error: 'message_too_long' }, 400);

  const client = new Client()
    .setEndpoint(
      process.env.APPWRITE_ENDPOINT ||
        process.env.APPWRITE_FUNCTION_API_ENDPOINT,
    )
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const tables = new TablesDB(client);

  try {
    const members = await resolveMembers(
      tables,
      userId,
      conversationId,
      participantIds,
    );
    if (members == null) {
      return res.json({ error: 'not_a_participant' }, 403);
    }

    const now = new Date().toISOString();
    const rowId = 'msg_' + crypto.randomBytes(10).toString('hex');
    const message = await tables.createRow({
      databaseId: DATABASE_ID,
      tableId: MESSAGES,
      rowId,
      data: {
        conversation_id: conversationId,
        sender_id: userId,
        sender_name: String(body.senderName ?? '').slice(0, 140),
        body: text.slice(0, 2000),
        created_at: now,
        updated_at: now,
      },
      permissions: [
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
        ...members.map((id) => Permission.read(Role.user(id))),
      ],
    });
    log(`message ${rowId} in ${conversationId} for ${members.length} member(s)`);
    return res.json({ id: message.$id, createdAt: message.created_at });
  } catch (err) {
    error(`chat send failed: ${err.message}`);
    return res.json({ error: 'send_failed', message: err.message }, 500);
  }
};

async function resolveMembers(tables, userId, conversationId, participantIds) {
  if (conversationId.startsWith('g_')) {
    const groupId = conversationId.slice(2);
    const group = await tables.getRow({
      databaseId: DATABASE_ID,
      tableId: GROUPS,
      rowId: groupId,
    });
    const members = Array.isArray(group.member_ids) ? group.member_ids : [];
    const coOwners = Array.isArray(group.co_owner_ids)
      ? group.co_owner_ids
      : [];
    if (
      group.owner_id !== userId &&
      !members.includes(userId) &&
      !coOwners.includes(userId)
    ) {
      return null;
    }
    return [...new Set([group.owner_id, ...coOwners, ...members])];
  }

  if (conversationId.startsWith('dm_')) {
    const other = participantIds.find((id) => id !== userId);
    if (!other) return null;
    if (expectedDmId(userId, other) !== conversationId) return null;
    const rows = await tables.listRows({
      databaseId: DATABASE_ID,
      tableId: FRIENDS,
      queries: [Query.equal('status', 'accepted'), Query.limit(200)],
    });
    const friends = rows.rows.some(
      (row) =>
        (row.requester_id === userId && row.addressee_id === other) ||
        (row.addressee_id === userId && row.requester_id === other),
    );
    return friends ? [userId, other] : null;
  }

  return null;
}

/// Keep in sync with `dmConversationId` in the Flutter client.
function expectedDmId(a, b) {
  const ids = [a, b].sort();
  let hash = 0x811c9dc5;
  for (const char of ids.join(':')) {
    hash ^= char.charCodeAt(0);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return 'dm_' + hash.toString(16).padStart(8, '0');
}

