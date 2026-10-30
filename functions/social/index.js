const {
  Client,
  TablesDB,
  Users,
  Query,
  Permission,
  Role,
} = require('node-appwrite');
const crypto = require('crypto');

const DATABASE_ID = 'singgah';
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

  const client = new Client()
    .setEndpoint(
      process.env.APPWRITE_ENDPOINT ||
        process.env.APPWRITE_FUNCTION_API_ENDPOINT,
    )
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const ctx = {
    tables: new TablesDB(client),
    users: new Users(client),
    res,
  };

  const action = String(body.action ?? '');
  try {
    switch (action) {
      case 'request':
        return await requestFriend(body, userId, ctx);
      case 'respond':
        return await respondFriend(body, userId, ctx);
      case 'remove':
        return await removeFriend(body, userId, ctx);
      case 'createGroup':
        return await createGroup(body, userId, ctx);
      case 'updateGroup':
        return await updateGroup(body, userId, ctx);
      case 'deleteGroup':
        return await deleteGroup(body, userId, ctx);
      default:
        return res.json({ error: 'unknown_action' }, 400);
    }
  } catch (err) {
    error(`${action} failed: ${err.message}`);
    return res.json({ error: 'social_failed', message: err.message }, 500);
  }
};

async function requestFriend(body, userId, { tables, users, res }) {
  const email = String(body.email ?? '')
    .trim()
    .toLowerCase();
  if (!email || !email.includes('@')) {
    return res.json({ error: 'invalid_email' }, 400);
  }

  const me = await users.get(userId);
  if ((me.email || '').toLowerCase() === email) {
    return res.json({ error: 'cannot_add_self' }, 409);
  }

  const found = await users.list({
    queries: [Query.equal('email', email), Query.limit(1)],
  });
  const target = found.users[0];
  if (!target) return res.json({ error: 'user_not_found' }, 404);

  const existing = await tables.listRows({
    databaseId: DATABASE_ID,
    tableId: FRIENDS,
    queries: [Query.limit(200)],
  });
  const duplicate = existing.rows.find(
    (row) =>
      !row.deleted_at &&
      ((row.requester_id === userId && row.addressee_id === target.$id) ||
        (row.addressee_id === userId && row.requester_id === target.$id)),
  );
  if (duplicate) {
    return res.json({ error: 'already_exists', status: duplicate.status }, 409);
  }

  const now = new Date().toISOString();
  const row = await tables.createRow({
    databaseId: DATABASE_ID,
    tableId: FRIENDS,
    rowId: 'fr_' + crypto.randomBytes(8).toString('hex'),
    data: {
      requester_id: userId,
      requester_name: me.name || me.email,
      requester_email: me.email,
      addressee_id: target.$id,
      addressee_email: target.email,
      status: 'pending',
      created_at: now,
      updated_at: now,
    },
    permissions: [
      Permission.read(Role.user(userId)),
      Permission.read(Role.user(target.$id)),
    ],
  });
  return res.json({ id: row.$id, status: row.status });
}

async function respondFriend(body, userId, { tables, res }) {
  const rowId = String(body.id ?? '');
  const accept = body.accept === true;
  const row = await tables.getRow({
    databaseId: DATABASE_ID,
    tableId: FRIENDS,
    rowId,
  });
  if (row.addressee_id !== userId) {
    return res.json({ error: 'not_addressee' }, 403);
  }
  if (row.status !== 'pending') {
    return res.json({ error: 'already_answered' }, 409);
  }

  if (!accept) {
    await tables.deleteRow({
      databaseId: DATABASE_ID,
      tableId: FRIENDS,
      rowId,
    });
    return res.json({ id: rowId, status: 'declined' });
  }

  const updated = await tables.updateRow({
    databaseId: DATABASE_ID,
    tableId: FRIENDS,
    rowId,
    data: { status: 'accepted', updated_at: new Date().toISOString() },
    permissions: [
      Permission.read(Role.user(row.requester_id)),
      Permission.read(Role.user(row.addressee_id)),
    ],
  });
  return res.json({ id: updated.$id, status: updated.status });
}

async function removeFriend(body, userId, { tables, res }) {
  const rowId = String(body.id ?? '');
  const row = await tables.getRow({
    databaseId: DATABASE_ID,
    tableId: FRIENDS,
    rowId,
  });
  if (row.requester_id !== userId && row.addressee_id !== userId) {
    return res.json({ error: 'not_member' }, 403);
  }
  await tables.deleteRow({
    databaseId: DATABASE_ID,
    tableId: FRIENDS,
    rowId,
  });
  return res.json({ id: rowId, status: 'removed' });
}

async function createGroup(body, userId, { tables, res }) {
  const name = String(body.name ?? '')
    .trim()
    .slice(0, 80);
  const memberIds = uniqueIds(body.memberIds).filter((id) => id !== userId);
  if (!name) return res.json({ error: 'name_required' }, 400);

  const now = new Date().toISOString();
  const row = await tables.createRow({
    databaseId: DATABASE_ID,
    tableId: GROUPS,
    rowId: 'gr_' + crypto.randomBytes(8).toString('hex'),
    data: {
      owner_id: userId,
      name,
      member_ids: memberIds,
      created_at: now,
      updated_at: now,
    },
    permissions: groupPermissions(userId, memberIds),
  });
  return res.json({ id: row.$id, name: row.name });
}

async function updateGroup(body, userId, { tables, res }) {
  const rowId = String(body.id ?? '');
  const row = await tables.getRow({
    databaseId: DATABASE_ID,
    tableId: GROUPS,
    rowId,
  });
  const currentCoOwners = Array.isArray(row.co_owner_ids)
    ? row.co_owner_ids
    : [];
  const isOwner = row.owner_id === userId;
  const isCoOwner = currentCoOwners.includes(userId);
  if (!isOwner && !isCoOwner) {
    return res.json({ error: 'not_allowed' }, 403);
  }

  const name =
    String(body.name ?? row.name)
      .trim()
      .slice(0, 80) || row.name;
  const memberIds = uniqueIds(body.memberIds).filter((id) => id !== userId);
  const coOwnerIds = isOwner
    ? uniqueIds(body.coOwnerIds).filter(
        (id) => id !== userId && (memberIds.includes(id) || id === row.owner_id),
      )
    : currentCoOwners;

  const updated = await tables.updateRow({
    databaseId: DATABASE_ID,
    tableId: GROUPS,
    rowId,
    data: {
      name,
      member_ids: memberIds,
      co_owner_ids: coOwnerIds,
      updated_at: new Date().toISOString(),
    },
    permissions: groupPermissions(row.owner_id, memberIds, coOwnerIds),
  });
  return res.json({ id: updated.$id, name: updated.name });
}

async function deleteGroup(body, userId, { tables, res }) {
  const rowId = String(body.id ?? '');
  const row = await tables.getRow({
    databaseId: DATABASE_ID,
    tableId: GROUPS,
    rowId,
  });
  if (row.owner_id !== userId) return res.json({ error: 'not_owner' }, 403);
  await tables.deleteRow({
    databaseId: DATABASE_ID,
    tableId: GROUPS,
    rowId,
  });
  return res.json({ id: rowId, status: 'deleted' });
}

function groupPermissions(ownerId, memberIds, coOwnerIds = []) {
  return [
    Permission.read(Role.user(ownerId)),
    Permission.update(Role.user(ownerId)),
    Permission.delete(Role.user(ownerId)),
    ...coOwnerIds.flatMap((id) => [
      Permission.read(Role.user(id)),
      Permission.update(Role.user(id)),
    ]),
    ...memberIds
      .filter((id) => !coOwnerIds.includes(id))
      .map((id) => Permission.read(Role.user(id))),
  ];
}

function uniqueIds(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((id) => String(id).trim()).filter(Boolean))];
}
