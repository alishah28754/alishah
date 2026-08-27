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
 * Looks up the Firebase UID for a MySQL user id. Orders store the MySQL
 * `user_id` (see orders.user_id), but FCM tokens live in Firestore keyed
 * by `firebase_uid` (see NotificationService._saveTokenToFirestore in the
 * Flutter app). This bridges the two.
 */
async function getFirebaseUid(mysqlUserId) {
  if (!mysqlUserId) return null;
  const [rows] = await pool.query(
    'SELECT firebase_uid FROM users WHERE id = ? LIMIT 1',
    [mysqlUserId]
  );
  const uid = rows[0]?.firebase_uid || null;
  console.log(`🔎 [push-debug] mysqlUserId=${mysqlUserId} -> firebase_uid=${uid}`);
  return uid;
}

/**
 * Sends a push notification to every device registered for a single user.
 * - Looks up their fcmTokens array from Firestore (users/{firebaseUid}).
 * - Sends to all of them (sendEachForMulticast).
 * - Cleans up any tokens Firebase reports as invalid/unregistered, so the
 *   array doesn't grow stale forever.
 * Never throws — a failed/missing token should never break an order flow,
 * so callers can fire-and-forget this.
 */
async function sendPushToUser(firebaseUid, { title, body, data = {} }) {
  if (!firebaseUid) {
    console.log('🔎 [push-debug] sendPushToUser called with no firebaseUid — aborting.');
    return;
  }

  try {
    const doc = await admin.firestore().collection('users').doc(firebaseUid).get();
    const docData = doc.data();
    console.log(`🔎 [push-debug] Firestore doc exists=${doc.exists} for uid=${firebaseUid}`);
    console.log(`🔎 [push-debug] preferences=${JSON.stringify(docData?.preferences)}`);
    console.log(`🔎 [push-debug] fcmTokens count=${Array.isArray(docData?.fcmTokens) ? docData.fcmTokens.length : 'not an array / missing'}`);

    // Respect the in-app toggle (NotificationService.setNotificationsEnabled
    // writes this). Defaults to true if the field has never been set (e.g.
    // brand-new account that hasn't opened Settings yet). This is the real
    // "off switch" — the app can't touch the OS-level permission, but it can
    // stop the backend from sending in the first place.
    const pushEnabled = docData?.preferences?.pushNotifications;
    if (pushEnabled === false) {
      console.log('🔎 [push-debug] pushNotifications preference is false — aborting.');
      return;
    }

    const tokens = docData?.fcmTokens;
    if (!Array.isArray(tokens) || tokens.length === 0) {
      console.log('🔎 [push-debug] no fcmTokens — aborting.');
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
      await admin.firestore().collection('users').doc(firebaseUid).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...deadTokens),
      });
    }
  } catch (err) {
    // Log only — notification delivery is best-effort, never fatal.
    console.error(`Push notification failed for ${firebaseUid}:`, err.message);
  }
}

/** Convenience wrapper: send by MySQL user_id (what orders/admin have on hand). */
async function sendPushToMysqlUser(mysqlUserId, payload) {
  const firebaseUid = await getFirebaseUid(mysqlUserId);
  if (!firebaseUid) return; // guest order or user not found — nothing to send
  await sendPushToUser(firebaseUid, payload);
}

/**
 * Broadcasts to every device subscribed to an FCM topic (e.g. 'new_products').
 * Used for announcements that aren't tied to one specific user, unlike the
 * per-user order-update pushes above. Devices subscribe/unsubscribe to the
 * topic client-side (see NotificationService._applyTopicSubscription).
 * Never throws — same fire-and-forget contract as sendPushToUser.
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

module.exports = { sendPushToUser, sendPushToMysqlUser, sendPushToTopic, getFirebaseUid };
