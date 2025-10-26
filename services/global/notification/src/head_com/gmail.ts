import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

if (!process.env.SENDER_EMAIL || !process.env.SENDER_PASSWORD) {
    throw new Error('Missing SENDER_EMAIL or SENDER_PASSWORD in environment variables.');
}

export const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.SENDER_EMAIL,
        pass: process.env.SENDER_PASSWORD
    }
});

export async function send_gmail(recipient: string, code: string): Promise<void> {
    const subject = "Notification";
    const message = `Code: ${code}`;

    const mailOptions = {
        from: process.env.SENDER_EMAIL,
        to: recipient,
        subject,
        text: message
    };

    await transporter.sendMail(mailOptions);
}
