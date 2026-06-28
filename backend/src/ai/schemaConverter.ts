import type { GeminiResponseSchema } from '../lib/gemini.js';

/**
 * A (loosely-typed) JSON Schema node — draft-07 style, as authored in each
 * task's `schema.json`. We only model the keywords we translate for Gemini;
 * everything else (title, $schema, maxItems, additionalProperties, …) is kept
 * for Ajv validation but ignored by the converter.
 */
export interface JsonSchema {
  type?: string | string[];
  description?: string;
  format?: string;
  enum?: unknown[];
  items?: JsonSchema;
  properties?: Record<string, JsonSchema>;
  required?: string[];
  [key: string]: unknown;
}

const TYPE_MAP: Record<string, string> = {
  string: 'STRING',
  number: 'NUMBER',
  integer: 'INTEGER',
  boolean: 'BOOLEAN',
  array: 'ARRAY',
  object: 'OBJECT',
};

/**
 * Converts a standard JSON Schema into the OpenAPI-subset shape Gemini accepts
 * as `responseSchema`. Handles the draft-07 nullable idiom (`"type": ["x","null"]`
 * → `nullable: true`), uppercases types, and recurses into objects/arrays.
 *
 * Pure: no I/O, no side-effects — same input always yields the same output.
 */
export const toGeminiSchema = (schema: JsonSchema): GeminiResponseSchema => {
  const out: Record<string, unknown> = {};

  let type = schema.type;
  if (Array.isArray(type)) {
    if (type.includes('null')) out.nullable = true;
    type = type.find((t) => t !== 'null');
  }
  if (typeof type === 'string') {
    out.type = TYPE_MAP[type] ?? 'STRING';
  }

  if (schema.description) out.description = schema.description;
  if (schema.format) out.format = schema.format;
  if (Array.isArray(schema.enum)) out.enum = schema.enum;
  if (schema.items) out.items = toGeminiSchema(schema.items);
  if (schema.properties) {
    out.properties = Object.fromEntries(
      Object.entries(schema.properties).map(([key, value]) => [
        key,
        toGeminiSchema(value),
      ]),
    );
  }
  if (Array.isArray(schema.required)) out.required = schema.required;

  return out as GeminiResponseSchema;
};
