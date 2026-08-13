require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 8000;

app.listen(PORT, () => {
  console.log('========================================');
  console.log('🚀 KTEX API running on http://localhost:' + PORT);
  console.log('   Health check: http://localhost:' + PORT + '/api/health');
  console.log('   Products:     http://localhost:' + PORT + '/api/products');
  console.log('   Banners:      http://localhost:' + PORT + '/api/banners');
  console.log('========================================');
});