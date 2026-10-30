const {
  Client,
  TablesDB,
  Users,
  Query,
  Permission,
  Role,
} = require('node-appwrite');

const DATABASE_ID = 'singgah';
const TITIPAN = 'titipan';
const RECIPIENTS = 'titipan_recipients';

module.exports = async ({ req, res, log, error }) => {
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) {
    return res.json({ error: 'not_authenticated' }, 401);
  }

  let token = '';
  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    token = String(body?.token ?? '').trim();
  } catch (_) {
    return res.json({ error: 'invalid_json' }, 400);
  }
  if (!token) return res.json({ error: 'invalid_invite' }, 400);

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT || process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const tables = new TablesDB(client);
  const users = new Users(client);

  try {
    const found = await tables.listRows({
      databaseId: DATABASE_ID,
      tableId: TITIPAN,
      queries: [Query.equal('invite_token', token), Query.limit(1)],
    });
    const titipan = found.rows[0];
    if (!titipan || titipan.deleted_at) {
      return res.json({ error: 'invalid_invite' }, 404);
    }
    if (titipan.sender_id === userId) {
      return res.json({ error: 'cannot_accept_own_invite' }, 409);
    }

    const existing = await tables.listRows({
      databaseId: DATABASE_ID,
      tableId: RECIPIENTS,
      queries: [
        Query.equal('titipan_id', titipan.$id),
        Query.equal('user_id', userId),
        Query.limit(1),
      ],
    });

    let recipient = existing.rows[0];
    let recipientPermissions = [
      Permission.read(Role.user(userId)),
      Permission.update(Role.user(userId)),
      Permission.read(Role.user(titipan.sender_id)),
    ];

    if (!recipient) {
      const account = await users.get(userId);
      const email = account.email ?? '';
      const emailMatch = await tables.listRows({
        databaseId: DATABASE_ID,
        tableId: RECIPIENTS,
        queries: [
          Query.equal('titipan_id', titipan.$id),
          Query.isNull('user_id'),
          Query.limit(20),
        ],
      });
      const placeholder = emailMatch.rows.find(
        (row) => (row.invited_email ?? '').toLowerCase() === email.toLowerCase(),
      );
      const acceptedAt = new Date().toISOString();
      if (placeholder) {
        recipientPermissions = [
          ...new Set([
            ...(placeholder.$permissions ?? []),
            ...recipientPermissions,
          ]),
        ];
        recipient = await tables.updateRow({
          databaseId: DATABASE_ID,
          tableId: RECIPIENTS,
          rowId: placeholder.$id,
          data: {
            user_id: userId,
            accepted_at: acceptedAt,
            updated_at: acceptedAt,
          },
          permissions: recipientPermissions,
        });
      } else {
        recipient = await tables.createRow({
          databaseId: DATABASE_ID,
          tableId: RECIPIENTS,
          rowId: 'recipient_' + cryptoRandomId(),
          data: {
            titipan_id: titipan.$id,
            user_id: userId,
            invited_email: email,
            accepted_at: acceptedAt,
            created_at: acceptedAt,
            updated_at: acceptedAt,
          },
          permissions: recipientPermissions,
        });
      }
    }

    const titipanPermissions = [
      ...new Set([
        ...(titipan.$permissions ?? []),
        Permission.read(Role.user(userId)),
      ]),
    ];
    const updatedTitipan = await tables.updateRow({
      databaseId: DATABASE_ID,
      tableId: TITIPAN,
      rowId: titipan.$id,
      data: { updated_at: titipan.updated_at ?? new Date().toISOString() },
      permissions: titipanPermissions,
    });

    return res.json({
      ...updatedTitipan,
      recipient_id: recipient.$id,
      accepted_at: recipient.accepted_at,
      invited_email: recipient.invited_email,
    });
  } catch (err) {
    error('accept-titipan failed: ' + err.message);
    return res.json({ error: 'could_not_accept' }, 500);
  }
};

function cryptoRandomId() {
  return require('crypto').randomBytes(10).toString('hex');
}

