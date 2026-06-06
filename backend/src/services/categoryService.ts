import { AppError } from '../lib/errors.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';

export interface CategoryDto {
  id: string;
  key: string;
  label: string;
  abbr: string;
  color: string;
  bgTint: string;
  isSystem: boolean;
}

const toCategoryDto = (row: {
  id: string;
  key: string;
  label: string;
  abbr: string;
  color: string;
  bgTint: string;
  isSystem: boolean;
}): CategoryDto => ({
  id: row.id,
  key: row.key,
  label: row.label,
  abbr: row.abbr,
  color: row.color,
  bgTint: row.bgTint,
  isSystem: row.isSystem,
});

function lightenHex(hex: string, factor = 0.85): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  const lr = Math.round(r + (255 - r) * factor);
  const lg = Math.round(g + (255 - g) * factor);
  const lb = Math.round(b + (255 - b) * factor);
  return (
    '#' +
    [lr, lg, lb]
      .map((v) => v.toString(16).padStart(2, '0').toUpperCase())
      .join('')
  );
}

function labelToKey(label: string): string {
  return label
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_]/g, '');
}

function autoAbbr(label: string): string {
  const trimmed = label.trim().toUpperCase();
  return trimmed.slice(0, Math.min(3, trimmed.length));
}

export const categoryService = {
  async getAll(userId?: string): Promise<CategoryDto[]> {
    const rows = await categoryRepository.findAll(userId);
    return rows.map(toCategoryDto);
  },

  async create(
    userId: string,
    input: { label: string; abbr?: string; color: string },
  ): Promise<CategoryDto> {
    const baseKey = labelToKey(input.label);
    // Append short timestamp suffix to avoid key collisions with system categories
    const key = `${baseKey || 'cat'}_${Date.now().toString(36)}`;

    const all = await categoryRepository.findAll(userId);
    const userCats = all.filter((c) => !c.isSystem);
    const sort = userCats.length > 0 ? Math.max(...userCats.map((c) => c.sort)) + 1 : 100;

    const abbr = input.abbr ?? autoAbbr(input.label);
    const bgTint = lightenHex(input.color);

    const created = await categoryRepository.create({
      userId,
      key,
      label: input.label,
      abbr: abbr.toUpperCase(),
      color: input.color,
      bgTint,
      sort,
    });
    return toCategoryDto(created);
  },

  async update(
    userId: string,
    id: string,
    input: { label?: string; abbr?: string; color?: string },
  ): Promise<CategoryDto> {
    const existing = await categoryRepository.findById(id);
    if (!existing || existing.deletedAt) {
      throw new AppError({ status: 404, code: 'CATEGORY_NOT_FOUND', message: 'Category not found' });
    }
    if (existing.isSystem) {
      throw new AppError({
        status: 403,
        code: 'SYSTEM_CATEGORY_IMMUTABLE',
        message: 'System categories cannot be modified',
      });
    }
    if (existing.userId !== userId) {
      throw new AppError({ status: 403, code: 'FORBIDDEN', message: 'Not allowed' });
    }

    const data: Parameters<typeof categoryRepository.update>[2] = {};
    if (input.label !== undefined) data.label = input.label;
    if (input.abbr !== undefined) data.abbr = input.abbr.toUpperCase();
    if (input.color !== undefined) {
      data.color = input.color;
      data.bgTint = lightenHex(input.color);
    }

    await categoryRepository.update(id, userId, data);
    const updated = await categoryRepository.findById(id);
    return toCategoryDto(updated!);
  },

  async delete(userId: string, id: string): Promise<void> {
    const existing = await categoryRepository.findById(id);
    if (!existing || existing.deletedAt) {
      throw new AppError({ status: 404, code: 'CATEGORY_NOT_FOUND', message: 'Category not found' });
    }
    if (existing.isSystem) {
      throw new AppError({
        status: 403,
        code: 'SYSTEM_CATEGORY_IMMUTABLE',
        message: 'System categories cannot be deleted',
      });
    }
    if (existing.userId !== userId) {
      throw new AppError({ status: 403, code: 'FORBIDDEN', message: 'Not allowed' });
    }

    const txCount = await transactionRepository.countByCategory(id, userId);
    if (txCount > 0) {
      throw new AppError({
        status: 409,
        code: 'CATEGORY_HAS_TRANSACTIONS',
        message: `This category has ${txCount} transaction${txCount === 1 ? '' : 's'}. Delete those transactions first, then you can delete the category.`,
      });
    }

    await categoryRepository.softDelete(id, userId);
  },
};
