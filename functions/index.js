const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const CHAT_MESSAGE_TYPE = 'chat_message';
const NEW_MATCH_TYPE = 'new_match';
const CHAT_CHANNEL_ID = 'chat_messages';
const MATCH_CHANNEL_ID = 'new_matches';

function collectTokens(userData) {
  const raw = userData?.fcmTokens;
  if (!Array.isArray(raw)) return [];
  return raw.filter((t) => typeof t === 'string' && t.length > 0);
}

async function sendPushToUser(db, userId, { title, body, data, channelId }) {
  const userSnap = await db.collection('users').doc(userId).get();
  const tokens = collectTokens(userSnap.data());
  if (tokens.length === 0) return;

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: {
      priority: 'high',
      notification: { channelId },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((resp, index) => {
    if (resp.success) return;
    const code = resp.error?.code ?? '';
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    await db.collection('users').doc(userId).update({
      fcmTokens: FieldValue.arrayRemove(...invalidTokens),
    });
  }
}

/**
 * Sends an FCM notification when a new chat message is created.
 */
exports.onChatMessageCreated = onDocumentCreated(
  {
    document: 'matches/{matchId}/messages/{messageId}',
    region: 'africa-south1',
  },
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const senderId = message.senderId?.toString?.() ?? '';
    const text = (message.text ?? '').toString().trim();
    if (!senderId || !text) return;

    const matchId = event.params.matchId;
    const db = getFirestore();

    const matchSnap = await db.collection('matches').doc(matchId).get();
    if (!matchSnap.exists) return;

    const matchData = matchSnap.data() ?? {};

    // Mutual match + first message: match push already covers the moment.
    if (matchData.mutualMatch === true) {
      const messagesSnap = await db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .limit(2)
        .get();
      if (messagesSnap.size <= 1) return;
    }

    const users = matchData.users;
    if (!Array.isArray(users) || users.length < 2) return;

    const recipientId = users.find((id) => id !== senderId);
    if (!recipientId) return;

    const senderSnap = await db.collection('users').doc(senderId).get();
    const senderName =
      (senderSnap.data()?.name ?? '').toString().trim() || 'Someone';
    const body = text.length > 120 ? `${text.slice(0, 117)}...` : text;

    await sendPushToUser(db, recipientId, {
      title: senderName,
      body,
      data: {
        type: CHAT_MESSAGE_TYPE,
        matchId,
      },
      channelId: CHAT_CHANNEL_ID,
    });
  },
);

/**
 * Notifies the user who was waiting when a mutual match is created.
 */
exports.onMutualMatchCreated = onDocumentCreated(
  {
    document: 'matches/{matchId}',
    region: 'africa-south1',
  },
  async (event) => {
    const match = event.data?.data();
    if (!match?.mutualMatch) return;

    const matchId = event.params.matchId;
    const users = match.users;
    const matchedBy = match.matchedBy?.toString?.() ?? '';

    if (!Array.isArray(users) || users.length < 2) return;

    const recipientId = matchedBy
      ? users.find((id) => id !== matchedBy)
      : null;
    if (!recipientId) return;

    const db = getFirestore();
    const matcherSnap = matchedBy
      ? await db.collection('users').doc(matchedBy).get()
      : null;
    const matcherName = matcherSnap
      ? (matcherSnap.data()?.name ?? '').toString().trim() || 'Someone'
      : 'Someone';

    await sendPushToUser(db, recipientId, {
      title: "It's a match!",
      body: `You and ${matcherName} liked each other`,
      data: {
        type: NEW_MATCH_TYPE,
        matchId,
      },
      channelId: MATCH_CHANNEL_ID,
    });
  },
);
