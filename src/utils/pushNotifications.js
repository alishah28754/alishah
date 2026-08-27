const admin = require('../config/firebase');
const pool = require('../config/db');

/**
 * Android notification channel to route a push into, based on its type.
 * Must match the channel IDs created client-side in notification_service.dart
 * (NotificationService._initChannels) — if these drift out of sync, Android
 * silently falls back to the default channel instead of erroring.
 */
function channelIdForType(type) {
  return type === 'new_product' ? 'new_products' : 'order_updates';
}

/**
 * Sends a push notification to every device registered for a single user.
 * - Reads the fcm_tokens JSON array straight off the MySQL `users` row.
 *   (Previously this looked up a Firebase Auth UID and read tokens from
 *   Firestore — that silently never worked for email/password customers,
 *   since they never get a Firebase Auth session client-side, so
 *   FirebaseAuth.instance.currentUser was always null and no token was
 *   ever saved for them.)
 * - Sends to all of them (sendEachForMulticast).
 * - Cleans up any tokens Firebase reports as invalid/unregistered, so the
 *   array doesn't grow stale forever.
 * Never throws — a failed/missing token should never break an order flow,
 * so callers can fire-and-forget this.
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
      // FCM data payloads must be string-only key/value pairs.
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
    });

    console.log(`🔎 [push-debug] sendEachForMulticast: successCount=${response.successCount}, failureCount=${response.failureCount}`);
    response.responses.forEach((res, i) => {
      if (!res.success) {
        console.log(`🔎 [push-debug] token[${i}] failed: ${res.error?.code} — ${res.error?.message}`);
      }
    });

    // Drop any tokens Firebase says are dead (uninstalled app, expired, etc.)
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
    }
  } catch (err) {
    // Log only — notification delivery is best-effort, never fatal.
    console.error(`Push notification failed for user ${mysqlUserId}:`, err.message);
  }
}

/**
 * Broadcasts to every device subscribed to an FCM topic (e.g. 'new_products').
 * Used for announcements that aren't tied to one specific user, unlike the
 * per-user order-update pushes above. Devices subscribe/unsubscribe to the
 * topic client-side (see NotificationService._applyTopicSubscription).
 * Never throws — same fire-and-forget contract as sendPushToMysqlUser.
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
    });
  } catch (err) {
    console.error(`Push notification to topic '${topic}' failed:`, err.message);
  }
}

module.exports = { sendPushToMysqlUser, sendPushToTopic };
