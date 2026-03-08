import { apiClient } from './client'

export interface CategoryDto {
  id: string
  name: string
  icon: string
  color: string
  isSystem: boolean
}

export const categoriesApi = {
  getAll: (): Promise<CategoryDto[]> =>
    apiClient.get<CategoryDto[]>('/categories').then((r) => r.data),
}
