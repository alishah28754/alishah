const pool = require('../config/db');
const { success, error } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { getAccessToken, buildCheckoutPayload, verifySignature } = require('../utils/payfast');

/* POST /api/payments/payfast/initiate - body: { order_number }
   Returns a URL for the Flutter app to open in a WebView. That URL renders
   an auto-submitting form which POSTs the signed payload to PayFast — the
   customer enters card/account details on PayFast's own hosted page. */
const initiatePayfast = asyncHandler(async (req, res) => {
  const { order_number } = req.body;
  if (!order_number) return error(res, 'order_number is required.', 400);

  const [rows] = await pool.query('SELECT * FROM orders WHERE order_number = ?', [order_number]);
  if (rows.length === 0) return error(res, 'Order not found.', 404);
  if (rows[0].status === 'Cancelled') return error(res, 'This order was cancelled.', 400);

  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return success(res, {
    checkout_url: `${baseUrl}/api/payments/payfast/checkout-form/${order_number}`,
  }, 'Open this URL in a WebView to complete payment.');
});

/* GET /api/payments/payfast/checkout-form/:orderNumber
   Renders the auto-submit HTML form. Point the Flutter WebView here. */
const renderCheckoutForm = asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM orders WHERE order_number = ?', [req.params.orderNumber]);
  if (rows.length === 0) return res.status(404).send('Order not found.');

  const order = rows[0];
  const customerIp = req.ip || req.headers['x-forwarded-for'] || '127.0.0.1';

  let token;
  try {
    token = await getAccessToken(customerIp);
  } catch (err) {
    console.error('PayFast token error:', err.message);
    return res.status(502).send('Could not reach PayFast. Please try again shortly.');
  }

  const payload = buildCheckoutPayload({ token, order, customerIp });

  const inputs = Object.entries(payload)
    .map(([key, value]) => `<input type="hidden" name="${key}" value="${String(value ?? '').replace(/"/g, '&quot;')}">`)
    .join('\n');

  res.send(`<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Redirecting to PayFast...</title></head>
<body style="font-family:sans-serif;text-align:center;padding-top:80px;">
  <p>Redirecting to secure payment page, please wait...</p>
  <form id="payfastForm" action="${process.env.PAYFAST_CHECKOUT_URL}" method="POST">
    ${inputs}
  </form>
  <script>document.getElementById('payfastForm').submit();</script>
</body>
</html>`);
});

/* GET /api/payments/payfast/success - PayFast redirects the customer's browser here */
const paymentSuccess = (req, res) => {
  res.send('<html><body style="font-family:sans-serif;text-align:center;padding-top:80px;">' +
    '<h2>Payment received ✅</h2><p>You can close this window and return to the KTEX app.</p></body></html>');
};

/* GET /api/payments/payfast/failure */
const paymentFailure = (req, res) => {
  res.send('<html><body style="font-family:sans-serif;text-align:center;padding-top:80px;">' +
    '<h2>Payment failed ❌</h2><p>Please return to the KTEX app and try again.</p></body></html>');
};

/* POST/GET /api/payments/payfast/callback - server-to-server notification from PayFast.
   NOTE: confirm exact field names against a real sandbox transaction (see utils/payfast.js note)
   and adjust the destructuring below if PayFast sends different keys for your account. */
const handlePayfastCallback = asyncHandler(async (req, res) => {
  const data = { ...req.query, ...req.body };
  const orderNumber = data.order_id || data.BASKET_ID || data.basket_id;
  const signature = data.signature || data.SIGNATURE;
  const statusCode = data.status_code || data.code;
  const transactionId = data.transaction_id || data.TRANSACTION_ID;

  if (!orderNumber) return error(res, 'Missing order reference in callback.', 400);

  const [rows] = await pool.query('SELECT * FROM orders WHERE order_number = ?', [orderNumber]);
  if (rows.length === 0) return error(res, 'Order not found.', 404);

  const order = rows[0];

  if (signature && !verifySignature({ amount: order.total, orderId: order.order_number, signature })) {
    console.error(`⚠️  PayFast signature mismatch for order ${orderNumber}`);
    return error(res, 'Signature verification failed.', 400);
  }

  // "00" = success per PayFast's documented error codes
  const paid = statusCode === '00';

  await pool.query(
    'UPDATE orders SET status = ?, payfast_txn_id = ? WHERE id = ?',
    [paid ? 'Confirmed' : 'Cancelled', transactionId || null, order.id]
  );

  return success(res, { order_number: orderNumber, paid }, 'Callback processed.');
});

module.exports = {
  initiatePayfast, renderCheckoutForm, paymentSuccess, paymentFailure, handlePayfastCallback,
};
