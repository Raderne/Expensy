import { CATEGORIES_API } from '@/api/clients'
import type { CategoryDto } from '@/api/types'

export type { CategoryDto }

export const categoriesApi = {
  getAll: (): Promise<CategoryDto[]> => CATEGORIES_API.getAll(),
}
