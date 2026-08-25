const { BrevoClient } = require('@getbrevo/brevo');

const brevo = new BrevoClient({
  apiKey: process.env.BREVO_API_KEY,
});

async function sendOtpEmail(toEmail, otp) {
  await brevo.transactionalEmails.sendTransacEmail({
    sender: {
      name: process.env.BREVO_SENDER_NAME,
      email: process.env.BREVO_SENDER_EMAIL,
    },
    to: [{ email: toEmail }],
    subject: 'Your KTEX Verification Code',
    htmlContent: `
      <p>Hello,</p>
      <p>Your verification code is:</p>
      <h2 style="letter-spacing:4px;">${otp}</h2>
      <p>This code expires in 10 minutes.</p>
    `,
  });
}

module.exports = { sendOtpEmail };
