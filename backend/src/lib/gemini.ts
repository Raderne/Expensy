import { env } from '../config/env.js';
import { AppError } from './errors.js';
import { logger } from './logger.js';

const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const TIMEOUT_MS = 12_000;

// Minimal OpenAPI-subset schema Gemini accepts for `responseSchema`. We type it
// loosely (the API surface is large) but keep callers honest via `as const`.
export type GeminiResponseSchema = Record<string, unknown>;

interface GenerateStructuredArgs {
  prompt: string;
  responseSchema: GeminiResponseSchema;
}

const aiUnavailable = (message: string, cause?: unknown): AppError => {
  if (cause) logger.error({ err: cause }, message);
  return new AppError({ status: 503, code: 'AI_UNAVAILABLE', message });
};

/**
 * Calls Gemini with a prompt and a JSON response schema, returning the parsed,
 * schema-shaped object. Forces JSON output (`responseMimeType` + `responseSchema`)
 * so callers get structured data rather than prose. Throws AppError(503,
 * AI_UNAVAILABLE) when the key is missing, the request times out, or the API
 * errors — the caller (and error handler) surface that as a graceful failure.
 *
 * The returned value is still validated with Zod by the caller; this function
 * only guarantees "some JSON object came back".
 */
export const generateStructured = async <T>({
  prompt,
  responseSchema,
}: GenerateStructuredArgs): Promise<T> => {
  if (!env.GEMINI_API_KEY) {
    throw aiUnavailable('AI estimates are not configured');
  }

  const url = `${API_BASE}/${env.GEMINI_MODEL}:generateContent?key=${env.GEMINI_API_KEY}`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  let res: Response;
  try {
    res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: controller.signal,
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: 'application/json',
          responseSchema,
          temperature: 0.2,
        },
      }),
    });
  } catch (err) {
    throw aiUnavailable('AI request failed', err);
  } finally {
    clearTimeout(timer);
  }

  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw aiUnavailable(`AI request failed (${res.status})`, detail);
  }

  let payload: {
    candidates?: { content?: { parts?: { text?: string }[] } }[];
  };
  try {
    payload = (await res.json()) as typeof payload;
  } catch (err) {
    throw aiUnavailable('AI returned a malformed response', err);
  }

  const text = payload.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw aiUnavailable('AI returned an empty response', payload);
  }

  try {
    return JSON.parse(text) as T;
  } catch (err) {
    throw aiUnavailable('AI returned non-JSON content', err);
  }
};

export const isAiConfigured = (): boolean => Boolean(env.GEMINI_API_KEY);
