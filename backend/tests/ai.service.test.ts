import { beforeEach, describe, expect, it, vi } from 'vitest';
import { toGeminiSchema } from '../src/ai/schemaConverter.js';

const generateStructured = vi.fn();
vi.mock('../src/lib/gemini.js', () => ({
  generateStructured: (...args: unknown[]) => generateStructured(...args),
}));

const { runAiTask, defineAiTask } = await import('../src/ai/aiService.js');

describe('toGeminiSchema', () => {
  it('uppercases scalar types', () => {
    expect(toGeminiSchema({ type: 'string' })).toEqual({ type: 'STRING' });
    expect(toGeminiSchema({ type: 'integer' })).toEqual({ type: 'INTEGER' });
  });

  it('maps the draft-07 nullable idiom to nullable: true', () => {
    expect(toGeminiSchema({ type: ['integer', 'null'], description: 'd' })).toEqual({
      type: 'INTEGER',
      nullable: true,
      description: 'd',
    });
  });

  it('carries enum and recurses into object properties', () => {
    const out = toGeminiSchema({
      type: 'object',
      properties: {
        confidence: { type: 'string', enum: ['low', 'high'] },
      },
      required: ['confidence'],
    });
    expect(out).toEqual({
      type: 'OBJECT',
      properties: { confidence: { type: 'STRING', enum: ['low', 'high'] } },
      required: ['confidence'],
    });
  });

  it('recurses into array items', () => {
    const out = toGeminiSchema({ type: 'array', items: { type: 'string' } });
    expect(out).toEqual({ type: 'ARRAY', items: { type: 'STRING' } });
  });
});

describe('runAiTask (goalEstimate task)', () => {
  const task = defineAiTask('goalEstimate');

  const valid = {
    reachable: true,
    estimatedMonths: 6,
    monthlyNetSavings: 500,
    confidence: 'high',
    summary: 'On track.',
    tips: ['Cook at home'],
  };

  beforeEach(() => generateStructured.mockReset());

  it('returns the model output when it matches the task schema', async () => {
    generateStructured.mockResolvedValue(valid);
    const result = await runAiTask<typeof valid>(task, { goalName: 'Car' });
    expect(result.estimatedMonths).toBe(6);
  });

  it('interpolates {{vars}} into the prompt sent to Gemini', async () => {
    generateStructured.mockResolvedValue(valid);
    await runAiTask(task, { goalName: 'Holiday' });
    const prompt = generateStructured.mock.calls[0]![0].prompt as string;
    expect(prompt).toContain('Holiday');
    expect(prompt).not.toContain('{{goalName}}');
  });

  it('passes the task token limits through to Gemini', async () => {
    generateStructured.mockResolvedValue(valid);
    const capped = defineAiTask('goalEstimate', {
      maxInputTokens: 1500,
      maxOutputTokens: 256,
    });
    await runAiTask(capped, {});
    const arg = generateStructured.mock.calls[0]![0];
    expect(arg.maxInputTokens).toBe(1500);
    expect(arg.maxOutputTokens).toBe(256);
  });

  it('leaves limits undefined when a task sets none (env default applies)', async () => {
    generateStructured.mockResolvedValue(valid);
    await runAiTask(task, {});
    const arg = generateStructured.mock.calls[0]![0];
    expect(arg.maxInputTokens).toBeUndefined();
    expect(arg.maxOutputTokens).toBeUndefined();
  });

  it('throws AI_UNAVAILABLE when output violates the schema', async () => {
    generateStructured.mockResolvedValue({ reachable: 'yes' });
    await expect(runAiTask(task, {})).rejects.toMatchObject({
      status: 503,
      code: 'AI_UNAVAILABLE',
    });
  });

  it('throws AI_UNAVAILABLE when confidence is outside the enum', async () => {
    generateStructured.mockResolvedValue({ ...valid, confidence: 'maybe' });
    await expect(runAiTask(task, {})).rejects.toMatchObject({
      code: 'AI_UNAVAILABLE',
    });
  });
});
