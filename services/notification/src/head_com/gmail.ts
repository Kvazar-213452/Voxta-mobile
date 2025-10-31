import nodemailer from 'nodemailer';
import { CONFIG } from '../config';

export let transporter: any = null;

export async function send_gmail(recipient: string, code: string): Promise<void> {
  if (transporter == null) {
    transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: CONFIG.SENDER_EMAIL,
        pass: CONFIG.SENDER_PASSWORD
      }
    });
  }

  const subject = "Notification";
  const message = `Code: ${code}`;

  const mailOptions = {
    from: CONFIG.SENDER_EMAIL,
    to: recipient,
    subject,
    text: message
  };

  await transporter.sendMail(mailOptions);
}
