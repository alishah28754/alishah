const crypto = require('crypto');
const axios = require('axios');

/**
 * PayFast (Pakistan — gopayfast.com) Hosted Checkout integration.
 *
 * IMPORTANT: PayFast's public docs are notoriously inconsistent about exact
 * field names and the live vs sandbox base URLs. Before going live:
 *   1. Log into your PayFast merchant dashboard and confirm PAYFAST_TOKEN_URL
 *      and PAYFAST_CHECKOUT_URL for your account (sandbox vs production).
 *   2. Do one full test transaction in sandbox and check server logs here —
 *      if PayFast's callback field names differ from what's read in
 *      paymentController.js's handlePayfastCallback(), adjust the field
 *      names there (they're all read from one place for exactly this reason).
 */

/**
 * Step 1: exchange Merchant ID + Secured Key for a short-lived access token.
 */
async function getAccessToken(customerIp) {
  const params = new URLSearchParams({
    merchant_id: process.env.PAYFAST_MERCHANT_ID,
    secured_key: process.env.PAYFAST_SECURED_KEY,
    grant_type: 'client_credentials',
    customer_ip: customerIp || '127.0.0.1',
  });

  const { data } = await axios.post(process.env.PAYFAST_TOKEN_URL, params.toString(), {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });

  if (!data || !data.token) {
    throw new Error(`PayFast token request failed: ${data && data.message ? data.message : 'no token returned'}`);
  }
  return data.token;
}

/**
 * Step 2: signature = md5(merchant_id:merchant_name:amount:order_id)
 * amount must be a plain integer/decimal string matching what's sent as TXNAMT.
 */
function buildSignature({ merchantId, merchantName, amount, orderId }) {
  const raw = `${merchantId}:${merchantName}:${amount}:${orderId}`;
  return crypto.createHash('md5').update(raw).digest('hex');
}

/**
 * Step 3: build the full hosted-checkout payload. The caller renders this as
 * an auto-submitting HTML form (see paymentController.js) POSTed to
 * PAYFAST_CHECKOUT_URL — this keeps raw card data off our server entirely.
 */
function buildCheckoutPayload({ token, order, customerIp }) {
  const merchantId = process.env.PAYFAST_MERCHANT_ID;
  const merchantName = process.env.PAYFAST_MERCHANT_NAME || 'KTEX Store';
  const amount = order.total; // integer PKR, matches DB `total` column

  const signature = buildSignature({ merchantId, merchantName, amount, orderId: order.order_number });

  return {
    MERCHANT_ID: merchantId,
    MERCHANT_NAME: merchantName,
    TOKEN: token,
    PROCCODE: '00',
    TXNAMT: String(amount),
    CUSTOMER_MOBILE_NO: order.phone,
    CUSTOMER_EMAIL_ADDRESS: order.email,
    SIGNATURE: signature,
    VERSION: 'KTEX-1.0',
    TXNDESC: `Order ${order.order_number} - KTEX Store`,
    SUCCESS_URL: process.env.PAYFAST_SUCCESS_URL,
    FAILURE_URL: process.env.PAYFAST_FAILURE_URL,
    BASKET_ID: order.order_number,
    ORDER_DATE: new Date().toISOString().slice(0, 19).replace('T', ' '),
    CHECKOUT_URL: process.env.PAYFAST_CALLBACK_URL,
  };
}

/** Recomputes the signature to verify PayFast's callback wasn't tampered with. */
function verifySignature({ amount, orderId, signature }) {
  const expected = buildSignature({
    merchantId: process.env.PAYFAST_MERCHANT_ID,
    merchantName: process.env.PAYFAST_MERCHANT_NAME || 'KTEX Store',
    amount,
    orderId,
  });
  return expected === signature;
}

module.exports = { getAccessToken, buildCheckoutPayload, buildSignature, verifySignature };
