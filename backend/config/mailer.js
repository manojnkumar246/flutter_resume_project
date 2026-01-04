import nodemailer from 'nodemailer';

// --- CONFIGURATION ---
const MY_EMAIL = 'sandakamanoj355@gmail.com'; 

// ⚠️ STEP 1: PASTE YOUR GOOGLE APP PASSWORD BELOW ⚠️
const MY_APP_PASSWORD = 'gqwqqigvolyeckju'; 

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: MY_EMAIL,
    pass: MY_APP_PASSWORD, 
  },
});

async function sendMail(opts) {
  try {
    const info = await transporter.sendMail({
      from: MY_EMAIL,     // Sender address
      to: opts.to,        // Receiver address
      subject: opts.subject,
      html: opts.html || opts.text, // HTML body
    });

    console.log(`✅ Email sent to ${opts.to}`);
    return info;
  } catch (error) {
    // We log the error but do NOT crash the app. 
    // This ensures the "Approve" button still works even if email fails.
    console.error(`❌ Email failed to send to ${opts.to}:`, error.message);
  }
}

export default { sendMail };