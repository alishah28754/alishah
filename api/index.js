// Vercel entry point - wraps Express app for serverless
const serverless = require('serverless-http');
const app = require('../src/app');

module.exports = serverless(app);