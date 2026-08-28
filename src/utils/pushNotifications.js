const admin = require('../config/firebase');
const pool = require('../config/db');

/**
 * Android notification channel to route a push into, based on its type.
 * Must match the channel IDs created client-side in notification_service.dart
 */
function channelIdForType(type) {
  if (type === 'order_update' || type === 'order_updates') {
    return 'order_updates';
  }
  return type === 'new_product' ? 'new_products' : 'order_updates';
}

/**
 * Sends a push notification to every device registered for a single user.
 */
async function sendPushToMysqlUser(mysqlUserId, { title, body, data = {} }) {
  if (!mysqlUserId) {
    console.log('🔎 [push-debug] sendPushToMysqlUser called with no mysqlUserId — aborting.');
    return;
  }

  try {
    const [rows] = await pool.query(
      'SELECT fcm_tokens FROM users WHERE id = ? LIMIT 1',
      [mysqlUserId]
    );

    if (rows.length === 0) {
      console.log(`🔎 [push-debug] no user found for id=${mysqlUserId} — aborting.`);
      return;
    }

    let tokens = [];
    try {
      tokens = rows[0].fcm_tokens ? JSON.parse(rows[0].fcm_tokens) : [];
      if (!Array.isArray(tokens)) tokens = [];
    } catch (_) {
      tokens = [];
    }

    console.log(`🔎 [push-debug] userId=${mysqlUserId} fcm_tokens count=${tokens.length}`);

    if (tokens.length === 0) {
      console.log('🔎 [push-debug] no fcm_tokens — aborting.');
      return;
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: channelIdForType(data.type),
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });

    console.log(`🔎 [push-debug] sendEachForMulticast: successCount=${response.successCount}, failureCount=${response.failureCount}`);
    response.responses.forEach((res, i) => {
      if (!res.success) {
        console.log(`🔎 [push-debug] token[${i}] failed: ${res.error?.code} — ${res.error?.message}`);
      }
    });

    // Drop any tokens Firebase says are dead
    const deadTokens = [];
    response.responses.forEach((res, i) => {
      if (!res.success) {
        const code = res.error?.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          deadTokens.push(tokens[i]);
        }
      }
    });

    if (deadTokens.length > 0) {
      const survivingTokens = tokens.filter((t) => !deadTokens.includes(t));
      await pool.query('UPDATE users SET fcm_tokens = ? WHERE id = ?', [
        JSON.stringify(survivingTokens),
        mysqlUserId,
      ]);
      console.log(`🔎 [push-debug] removed ${deadTokens.length} dead tokens`);
    }
  } catch (err) {
    console.error(`Push notification failed for user ${mysqlUserId}:`, err.message);
  }
}

/**
 * Broadcasts to every device subscribed to an FCM topic
 */
async function sendPushToTopic(topic, { title, body, data = {} }) {
  try {
    await admin.messaging().send({
      topic,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: channelIdForType(data.type),
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });
    console.log(`✅ Push sent to topic: ${topic}`);
  } catch (err) {
    console.error(`Push notification to topic '${topic}' failed:`, err.message);
  }
}

module.exports = { sendPushToMysqlUser, sendPushToTopic };
