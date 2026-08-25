const brevo = require('@getbrevo/brevo');

let apiInstance = new brevo.TransactionalEmailsApi();
apiInstance.setApiKey(brevo.TransactionalEmailsApiApiKeys.apiKey, process.env.BREVO_API_KEY);

async function sendOtpEmail(toEmail, otp) {
  let sendSmtpEmail = new brevo.SendSmtpEmail();

  sendSmtpEmail.sender = {
    name: process.env.BREVO_SENDER_NAME,
    email: process.env.BREVO_SENDER_EMAIL,
  };
  sendSmtpEmail.to = [{ email: toEmail }];
  sendSmtpEmail.subject = 'Your KTEX Verification Code';
  sendSmtpEmail.htmlContent = `
    <p>Hello,</p>
    <p>Your verification code is:</p>
    <h2 style="letter-spacing:4px;">${otp}</h2>
    <p>This code expires in 10 minutes.</p>
  `;

  await apiInstance.sendTransacEmail(sendSmtpEmail);
}

module.exports = { sendOtpEmail };
