import { readFileSync } from 'node:fs';
import { Ajv, type ValidateFunction } from 'ajv';
import { AppError } from '../lib/errors.js';
import { logger } from '../lib/logger.js';
import { generateStructured, type GeminiResponseSchema } from '../lib/gemini.js';
import { toGeminiSchema, type JsonSchema } from './schemaConverter.js';

/**
 * A reusable AI capability. Each task is a folder under `src/ai/tasks/<key>/`
 * holding two files:
 *   - `prompt.md`    — the instruction template (inputs), with `{{var}}` slots.
 *   - `schema.json`  — the JSON Schema describing the expected output.
 *
 * [TOutput] is the TypeScript shape the output is asserted to, declared by the
 * caller via [defineAiTask]. The runtime guarantee comes from the JSON Schema.
 */
export interface AiTask<TOutput> {
  readonly key: string;
  /** Phantom marker so [runAiTask] can infer [TOutput]; never read at runtime. */
  readonly __output?: TOutput;
}

/** Declares an AI task and binds its output type. */
export const defineAiTask = <TOutput>(key: string): AiTask<TOutput> => ({ key });

interface CompiledTask {
  prompt: string;
  geminiSchema: GeminiResponseSchema;
  validate: ValidateFunction;
}

const ajv = new Ajv({ allErrors: true, strict: false });
const tasksDir = new URL('./tasks/', import.meta.url);
const cache = new Map<string, CompiledTask>();

// Loads + compiles a task's prompt and schema once, then memoizes. Resolved
// relative to the compiled file so it works under tsx (src/) and node (dist/,
// where postbuild copies `ai/tasks`).
const compileTask = (key: string): CompiledTask => {
  const cached = cache.get(key);
  if (cached) return cached;

  const prompt = readFileSync(new URL(`${key}/prompt.md`, tasksDir), 'utf8');
  const schema = JSON.parse(
    readFileSync(new URL(`${key}/schema.json`, tasksDir), 'utf8'),
  ) as JsonSchema;

  const compiled: CompiledTask = {
    prompt,
    geminiSchema: toGeminiSchema(schema),
    validate: ajv.compile(schema),
  };
  cache.set(key, compiled);
  return compiled;
};

const fillTemplate = (
  tpl: string,
  vars: Record<string, string | number>,
): string => tpl.replace(/\{\{(\w+)\}\}/g, (_, k: string) => String(vars[k] ?? ''));

/**
 * Runs an AI task: interpolates the prompt with [variables], asks Gemini for a
 * response constrained to the task's schema, validates the result against that
 * same schema, and returns it typed as [TOutput].
 *
 * Pure with respect to the task definition: behaviour is driven entirely by the
 * task's `prompt.md` + `schema.json`, with no per-feature branching — adding a
 * new AI capability means adding a task folder, not editing this file. Throws
 * `AppError(503, AI_UNAVAILABLE)` if the model is down or returns off-schema data.
 */
export const runAiTask = async <TOutput>(
  task: AiTask<TOutput>,
  variables: Record<string, string | number> = {},
): Promise<TOutput> => {
  const { prompt, geminiSchema, validate } = compileTask(task.key);

  const raw = await generateStructured<unknown>({
    prompt: fillTemplate(prompt, variables),
    responseSchema: geminiSchema,
  });

  if (!validate(raw)) {
    logger.error(
      { task: task.key, errors: validate.errors },
      'AI output failed schema validation',
    );
    throw new AppError({
      status: 503,
      code: 'AI_UNAVAILABLE',
      message: 'AI returned an unexpected response shape',
    });
  }

  return raw as TOutput;
};
