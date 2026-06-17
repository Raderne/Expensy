import { AppError } from '../lib/errors.js';
import { contactRepository } from '../repositories/contactRepository.js';

export interface ContactDto {
  id: string;
  name: string;
  color: string | null;
}

type ContactRow = Awaited<ReturnType<typeof contactRepository.findByUser>>[number];

const toDto = (row: ContactRow): ContactDto => ({
  id: row.id,
  name: row.name,
  color: row.color,
});

const notFound = () =>
  new AppError({ status: 404, code: 'CONTACT_NOT_FOUND', message: 'Contact not found' });

export const contactService = {
  async list(userId: string): Promise<ContactDto[]> {
    const rows = await contactRepository.findByUser(userId);
    return rows.map(toDto);
  },

  async create(userId: string, input: { name: string; color?: string }): Promise<ContactDto> {
    const created = await contactRepository.create({
      userId,
      name: input.name,
      color: input.color ?? null,
    });
    return toDto(created);
  },

  async update(
    userId: string,
    id: string,
    input: { name?: string; color?: string | null },
  ): Promise<ContactDto> {
    const existing = await contactRepository.findById(id, userId);
    if (!existing) throw notFound();

    const data: { name?: string; color?: string | null } = {};
    if (input.name !== undefined) data.name = input.name;
    if (input.color !== undefined) data.color = input.color;

    await contactRepository.update(id, userId, data);
    const updated = await contactRepository.findById(id, userId);
    return toDto(updated!);
  },

  async delete(userId: string, id: string): Promise<void> {
    const existing = await contactRepository.findById(id, userId);
    if (!existing) throw notFound();
    await contactRepository.softDelete(id, userId);
  },
};
