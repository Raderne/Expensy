import nodemailer, { type Transporter } from 'nodemailer';
import { env } from '../config/env.js';
import { logger } from './logger.js';

export interface MailMessage {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

// Lazily build the SMTP transport so dev/test runs that never send mail don't
// open a connection. Null when SMTP is not configured.
let transporter: Transporter | null | undefined;

const getTransporter = (): Transporter | null => {
  if (transporter !== undefined) return transporter;
  if (!env.SMTP_HOST) {
    transporter = null;
    return transporter;
  }
  transporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: env.SMTP_PORT ?? 587,
    secure: (env.SMTP_PORT ?? 587) === 465,
    auth:
      env.SMTP_USER && env.SMTP_PASSWORD
        ? { user: env.SMTP_USER, pass: env.SMTP_PASSWORD }
        : undefined,
  });
  return transporter;
};

const FROM = env.SMTP_FROM ?? 'Expensy <no-reply@expensy.app>';

/**
 * Sends an email when SMTP is configured; otherwise logs it (including the
 * body) so flows like password-reset OTP remain testable in local dev with no
 * mail provider.
 */
export const sendMail = async (msg: MailMessage): Promise<void> => {
  const tx = getTransporter();
  if (!tx) {
    logger.info(
      { to: msg.to, subject: msg.subject, body: msg.text },
      'Email not sent (SMTP not configured) — logging message instead',
    );
    return;
  }
  await tx.sendMail({ from: FROM, to: msg.to, subject: msg.subject, text: msg.text, html: msg.html });
};
