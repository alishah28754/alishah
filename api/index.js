// Vercel entry point. Vercel runs everything as serverless functions -- this
// file wraps the existing Express app (unchanged) so every request is routed
// into it. Locally, server.js (npm start) is still used instead -- this file
// is only invoked by Vercel's Node.js runtime.
const serverless = require('serverless-http');
const app = require('../src/app');

module.exports = serverless(app);
