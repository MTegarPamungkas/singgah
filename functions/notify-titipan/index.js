const {
  Client,
  TablesDB,
  Messaging,
  ID,
} = require('node-appwrite');

const DATABASE_ID = 'singgah';

module.exports = async ({ req, res, log, error }) => {
  let row = {};
  try {
    row = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (_) {
    return res.json({ skipped: 'invalid_payload' }, 400);
  }

  const userId = row?.user_id?.toString();
  const titipanId = row?.titipan_id?.toString();
  if (!userId || !titipanId) {
    // Email placeholders have no account yet; nothing to push to.
    return res.json({ skipped: 'no_recipient' });
  }

  const client = new Client()
    .setEndpoint(
      process.env.APPWRITE_ENDPOINT ||
        process.env.APPWRITE_FUNCTION_API_ENDPOINT,
    )
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const tables = new TablesDB(client);
  const messaging = new Messaging(client);

  try {
    const titipan = await tables.getRow({
      databaseId: DATABASE_ID,
      tableId: 'titipan',
      rowId: titipanId,
    });
    const sender = titipan.sender_name || 'Seseorang';
    const title = titipan.title || 'Titipan baru';
    const place = titipan.place_name || titipan.address || 'Titik';

    await messaging.createPush({
      messageId: ID.unique(),
      title: `Titipan dari ${sender}`,
      body: `${title} · ${place}`,
      users: [userId],
      data: {
        type: 'titipan',
        titipanId,
      },
    });
    log(`push sent to ${userId} for ${titipanId}`);
    return res.json({ sent: true });
  } catch (err) {
    error(`notify-titipan failed: ${err.message}`);
    // A push failure must never break invite acceptance.
    return res.json({ sent: false }, 200);
  }
};
