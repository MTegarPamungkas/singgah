const {
  Client,
  TablesDB,
  Query,
  Permission,
  Role,
} = require('node-appwrite');
const crypto = require('crypto');

const DATABASE_ID = 'singgah';
const TITIPAN = 'titipan';
const RECIPIENTS = 'titipan_recipients';
const FRIENDS = 'friendships';
const GROUPS = 'groups';

module.exports = async ({ req, res, log, error }) => {
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) return res.json({ error: 'not_authenticated' }, 401);

  let body = {};
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (_) {
    return res.json({ error: 'invalid_json' }, 400);
  }

  const titipan = body.titipan;
  if (!titipan || typeof titipan !== 'object') {
    return res.json({ error: 'titipan_required' }, 400);
  }
  const titipanId = String(titipan.id ?? '').trim();
  if (!titipanId) return res.json({ error: 'titipan_id_required' }, 400);
  if (String(titipan.sender_id ?? '') !== userId) {
    return res.json({ error: 'not_sender' }, 403);
  }

  const client = new Client()
    .setEndpoint(
      process.env.APPWRITE_ENDPOINT ||
        process.env.APPWRITE_FUNCTION_API_ENDPOINT,
    )
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const tables = new TablesDB(client);

  try {
    const friendIds = await resolveFriends(tables, userId, body.friendIds);
    const groupMemberIds = await resolveGroups(tables, userId, body.groupIds);
    const recipients = [...new Set([...friendIds, ...groupMemberIds])].filter(
      (id) => id && id !== userId,
    );
    if (recipients.length === 0) {
      return res.json({ error: 'no_recipients' }, 400);
    }

    const now = new Date().toISOString();
    const permissions = [
      Permission.read(Role.user(userId)),
      Permission.update(Role.user(userId)),
      Permission.delete(Role.user(userId)),
      ...recipients.map((id) => Permission.read(Role.user(id))),
    ];

    await tables.upsertRow({
      databaseId: DATABASE_ID,
      tableId: TITIPAN,
      rowId: titipanId,
      data: {
        sender_id: userId,
        sender_name: String(titipan.sender_name ?? '').slice(0, 140),
        place_id: titipan.place_id ? String(titipan.place_id) : null,
        place_name: String(titipan.place_name ?? '').slice(0, 140),
        latitude: Number(titipan.latitude) || 0,
        longitude: Number(titipan.longitude) || 0,
        radius_meters: clampRadius(titipan.radius_meters),
        title: String(titipan.title ?? '').slice(0, 140),
        body: String(titipan.body ?? '').slice(0, 2000),
        trigger: titipan.trigger === 'leave' ? 'leave' : 'arrive',
        invite_token: String(titipan.invite_token ?? '').slice(0, 64),
        recipient_hint: String(titipan.recipient_hint ?? '').slice(0, 140),
        created_at: titipan.created_at || now,
        updated_at: now,
      },
      permissions,
    });

    for (const recipientId of recipients) {
      const rowId =
        'r_' +
        crypto
          .createHash('sha256')
          .update(`${titipanId}:${recipientId}`)
          .digest('hex')
          .slice(0, 30);
      const data = {
        titipan_id: titipanId,
        user_id: recipientId,
        accepted_at: now,
        created_at: now,
        updated_at: now,
      };
      const permissions = [
        Permission.read(Role.user(recipientId)),
        Permission.update(Role.user(recipientId)),
        Permission.read(Role.user(userId)),
      ];
      try {
        await tables.createRow({
          databaseId: DATABASE_ID,
          tableId: RECIPIENTS,
          rowId,
          data,
          permissions,
        });
      } catch (err) {
        if (err.code !== 409) throw err;
        await tables.updateRow({
          databaseId: DATABASE_ID,
          tableId: RECIPIENTS,
          rowId,
          data,
          permissions,
        });
      }
    }

    log(`sent ${titipanId} to ${recipients.length} recipient(s)`);
    return res.json({ recipients: recipients.length });
  } catch (err) {
    error(`send-titipan failed: ${err.message}`);
    return res.json({ error: 'send_failed', message: err.message }, 500);
  }
};

async function resolveFriends(tables, userId, friendIds) {
  if (!Array.isArray(friendIds) || friendIds.length === 0) return [];
  const rows = await tables.listRows({
    databaseId: DATABASE_ID,
    tableId: FRIENDS,
    queries: [Query.equal('status', 'accepted'), Query.limit(200)],
  });
  const accepted = new Set();
  for (const row of rows.rows) {
    if (row.requester_id === userId) accepted.add(row.addressee_id);
    if (row.addressee_id === userId) accepted.add(row.requester_id);
  }
  return friendIds
    .map((id) => String(id))
    .filter((id) => accepted.has(id));
}

async function resolveGroups(tables, userId, groupIds) {
  if (!Array.isArray(groupIds) || groupIds.length === 0) return [];
  const result = [];
  for (const groupId of groupIds) {
    try {
      const group = await tables.getRow({
        databaseId: DATABASE_ID,
        tableId: GROUPS,
        rowId: String(groupId),
      });
      const members = Array.isArray(group.member_ids) ? group.member_ids : [];
      if (group.owner_id !== userId && !members.includes(userId)) continue;
      result.push(group.owner_id, ...members);
    } catch (err) {
      if (err.code !== 404) throw err;
    }
  }
  return result;
}

function clampRadius(value) {
  const radius = Number(value) || 150;
  return Math.max(100, Math.min(2000, Math.round(radius)));
}
