const { BrevoClient } = require('@getbrevo/brevo');

/**
 * Check if Brevo is properly configured in .env
 */
const isBrevoConfigured = () => {
  return !!(process.env.BREVO_API_KEY && 
            process.env.BREVO_SENDER_EMAIL && 
            process.env.BREVO_SENDER_NAME);
};

/**
 * Send OTP email via Brevo
 */
async function sendOtpEmail(toEmail, otp) {
  if (!isBrevoConfigured()) {
    console.warn('⚠️ Brevo not configured. OTP email would be sent to:', toEmail);
    return { success: false, message: 'Brevo not configured' };
  }

  try {
    const brevo = new BrevoClient({
      apiKey: process.env.BREVO_API_KEY,
    });

    await brevo.transactionalEmails.sendTransacEmail({
      sender: {
        name: process.env.BREVO_SENDER_NAME,
        email: process.env.BREVO_SENDER_EMAIL,
      },
      to: [{ email: toEmail }],
      subject: 'Your KTEX Verification Code',
      htmlContent: `
        <html>
          <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9fafb;">
            <div style="background: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
              <h2 style="color: #4F46E5; margin-bottom: 20px;">KTEX Store</h2>
              <p style="color: #374151; font-size: 16px;">Hello,</p>
              <p style="color: #374151; font-size: 16px;">Your verification code is:</p>
              <div style="text-align: center; margin: 30px 0;">
                <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #4F46E5; background: #EEF2FF; padding: 12px 24px; border-radius: 8px;">${otp}</span>
              </div>
              <p style="color: #6B7280; font-size: 14px;">This code expires in <strong>10 minutes</strong>.</p>
              <hr style="border: 1px solid #E5E7EB; margin: 30px 0;" />
              <p style="color: #9CA3AF; font-size: 12px; text-align: center;">Thanks,<br/>KTEX Team</p>
            </div>
          </body>
        </html>
      `,
    });
    
    console.log(`✅ OTP email sent to ${toEmail}`);
    return { success: true };
  } catch (err) {
    console.error('❌ Brevo OTP email failed:', err.message);
    if (err.response) {
      console.error('Brevo API Error:', err.response.body);
    }
    return { success: false, error: err.message };
  }
}

/**
 * Send order status update email via Brevo
 */
async function sendOrderStatusEmail(toEmail, orderId, status, customerName) {
  if (!isBrevoConfigured()) {
    console.warn('⚠️ Brevo not configured. Order email would be sent to:', toEmail);
    return { success: false, message: 'Brevo not configured' };
  }

  try {
    const brevo = new BrevoClient({
      apiKey: process.env.BREVO_API_KEY,
    });

    const statusColors = {
      'Processing': '#F59E0B',
      'Shipped': '#3B82F6',
      'Delivered': '#10B981',
      'Cancelled': '#EF4444',
      'Refunded': '#8B5CF6'
    };

    const statusMessages = {
      'Processing': 'Your order has been confirmed and is being processed.',
      'Shipped': 'Your order has been shipped! You will receive tracking details soon.',
      'Delivered': 'Your order has been delivered successfully!',
      'Cancelled': 'Your order has been cancelled.',
      'Refunded': 'Your order has been refunded.'
    };

    await brevo.transactionalEmails.sendTransacEmail({
      sender: {
        name: process.env.BREVO_SENDER_NAME,
        email: process.env.BREVO_SENDER_EMAIL,
      },
      to: [{ email: toEmail }],
      subject: `Order ${status}: ${orderId} - KTEX Store`,
      htmlContent: `
        <html>
          <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9fafb;">
            <div style="background: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
              <h2 style="color: #4F46E5; margin-bottom: 20px;">KTEX Store</h2>
              <p style="color: #374151; font-size: 16px;">Hello ${customerName || 'Customer'},</p>
              <div style="background: #F3F4F6; border-radius: 8px; padding: 16px; margin: 20px 0;">
                <p style="margin: 0; color: #6B7280;">Order ID</p>
                <p style="margin: 4px 0 0; font-size: 18px; font-weight: bold; color: #1F2937;">${orderId}</p>
              </div>
              <div style="text-align: center; margin: 30px 0;">
                <span style="display: inline-block; background: ${statusColors[status] || '#6B7280'}; color: white; padding: 8px 24px; border-radius: 20px; font-weight: bold; font-size: 18px;">
                  ${status}
                </span>
                <p style="color: #4B5563; font-size: 16px; margin-top: 16px;">${statusMessages[status] || 'Your order status has been updated.'}</p>
              </div>
              <hr style="border: 1px solid #E5E7EB; margin: 30px 0;" />
              <p style="color: #9CA3AF; font-size: 12px; text-align: center;">
                Track your order at: <a href="https://ktex.up.railway.app/track/${orderId}" style="color: #4F46E5;">Track Order</a>
                <br/><br/>Thanks,<br/>KTEX Team
              </p>
            </div>
          </body>
        </html>
      `,
    });
    
    console.log(`✅ Order status email sent to ${toEmail} for order ${orderId}`);
    return { success: true };
  } catch (err) {
    console.error('❌ Brevo order email failed:', err.message);
    return { success: false, error: err.message };
  }
}

module.exports = { sendOtpEmail, sendOrderStatusEmail, isBrevoConfigured };
