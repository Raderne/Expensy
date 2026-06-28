import { env } from '../config/env.js';
import { AppError } from './errors.js';
import { logger } from './logger.js';

const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const TIMEOUT_MS = 12_000;
// Transient network blips (connect timeouts, dropped Wi-Fi, DNS hiccups) surface
// as `fetch failed` TypeErrors before any HTTP status is returned. We retry only
// those — never an actual HTTP error response, which is a real signal.
const MAX_ATTEMPTS = 3;
const RETRY_BASE_DELAY_MS = 400;

const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

// Minimal OpenAPI-subset schema Gemini accepts for `responseSchema`. We type it
// loosely (the API surface is large) but keep callers honest via `as const`.
export type GeminiResponseSchema = Record<string, unknown>;

interface GenerateStructuredArgs {
  prompt: string;
  responseSchema: GeminiResponseSchema;
  /** Caps the prompt size; oversized prompts fail fast (default: env). */
  maxInputTokens?: number;
  /** Caps the model's response length via `maxOutputTokens` (default: env). */
  maxOutputTokens?: number;
  /**
   * Thinking-token budget for 2.5+ "thinking" models. `0` disables reasoning so
   * `maxOutputTokens` caps the actual answer (right for structured extraction).
   * Only sent when defined — non-thinking models reject the field. Default: env.
   */
  thinkingBudget?: number;
}

// Cheap, dependency-free token estimate (~4 chars/token for English). Used only
// as a guard rail, so an approximation is fine — we never bill against it.
const estimateTokens = (text: string): number => Math.ceil(text.length / 4);

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
  maxInputTokens = env.GEMINI_MAX_INPUT_TOKENS,
  maxOutputTokens = env.GEMINI_MAX_OUTPUT_TOKENS,
  thinkingBudget = env.GEMINI_THINKING_BUDGET,
}: GenerateStructuredArgs): Promise<T> => {
  if (!env.GEMINI_API_KEY) {
    throw aiUnavailable('AI estimates are not configured');
  }

  const inputTokens = estimateTokens(prompt);
  if (inputTokens > maxInputTokens) {
    throw aiUnavailable(
      `AI prompt too large (~${inputTokens} tokens > ${maxInputTokens} cap)`,
    );
  }

  const generationConfig: Record<string, unknown> = {
    responseMimeType: 'application/json',
    responseSchema,
    temperature: 0.2,
    maxOutputTokens,
  };
  // Only attach for thinking-capable models; others reject `thinkingConfig`.
  if (thinkingBudget !== undefined) {
    generationConfig.thinkingConfig = { thinkingBudget };
  }

  const url = `${API_BASE}/${env.GEMINI_MODEL}:generateContent?key=${env.GEMINI_API_KEY}`;
  const body = JSON.stringify({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    generationConfig,
  });

  let res: Response | undefined;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body,
      });
      break;
    } catch (err) {
      // Network-level failure (no HTTP response). Retry with backoff unless we've
      // exhausted attempts, then surface as a graceful 503.
      if (attempt >= MAX_ATTEMPTS) {
        throw aiUnavailable('AI request failed', err);
      }
      logger.warn(
        { err, attempt, maxAttempts: MAX_ATTEMPTS },
        'AI request network error, retrying',
      );
      await sleep(RETRY_BASE_DELAY_MS * attempt);
    } finally {
      clearTimeout(timer);
    }
  }

  // Loop either `break`s with a response or throws on the final attempt.
  if (!res) {
    throw aiUnavailable('AI request failed');
  }

  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw aiUnavailable(`AI request failed (${res.status})`, detail);
  }

  let payload: {
    candidates?: {
      content?: { parts?: { text?: string }[] };
      finishReason?: string;
    }[];
  };
  try {
    payload = (await res.json()) as typeof payload;
  } catch (err) {
    throw aiUnavailable('AI returned a malformed response', err);
  }

  // When the output cap is hit the response is truncated (partial JSON), which
  // would otherwise fail as confusing "non-JSON content". Surface it plainly so
  // the cap can be raised for this task.
  if (payload.candidates?.[0]?.finishReason === 'MAX_TOKENS') {
    throw aiUnavailable(
      `AI response hit the output cap (${maxOutputTokens} tokens); raise maxOutputTokens`,
    );
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
