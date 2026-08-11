const admin = require('firebase-admin');

if (!admin.apps.length) {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  // .env stores literal "\n" — convert back to real newlines for the PEM key
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey || !privateKey.includes('BEGIN PRIVATE KEY')) {
    console.error(
      '❌ Firebase Admin is not configured (or still has placeholder values). ' +
      'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY in .env ' +
      '(Firebase Console -> Project Settings -> Service Accounts -> Generate new private key). ' +
      'Auth-protected routes will fail until this is set.'
    );
  } else {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
      });
      console.log('✅ Firebase Admin initialized for project:', projectId);
    } catch (err) {
      console.error('❌ Firebase Admin failed to initialize:', err.message);
      console.error('   Auth-protected routes will fail until FIREBASE_* env vars are fixed.');
    }
  }
}

module.exports = admin;
