require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 8000;

app.listen(PORT, () => {
  console.log(`🚀 KTEX API running on http://localhost:${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/api/health`);
});
