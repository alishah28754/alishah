const admin = require('firebase-admin');

/**
 * Firebase Admin SDK initialization for verifying ID tokens
 * from the Flutter app. Uses service account credentials.
 */
if (!admin.apps.length) {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');

  // Validate credentials
  if (!projectId || !clientEmail || !privateKey || !privateKey.includes('BEGIN PRIVATE KEY')) {
    console.warn(
      '⚠️  Firebase Admin is not properly configured. ' +
      'Auth-protected routes will fail until FIREBASE_* env vars are set.'
    );
  } else {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({ 
          projectId, 
          clientEmail, 
          privateKey 
        }),
      });
      console.log('✅ Firebase Admin initialized for project:', projectId);
    } catch (err) {
      console.error('❌ Firebase Admin initialization failed:', err.message);
    }
  }
}

module.exports = admin;