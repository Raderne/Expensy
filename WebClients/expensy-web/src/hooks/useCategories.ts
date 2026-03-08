import { useQuery } from '@tanstack/react-query'
import { categoriesApi, CategoryDto } from '@/api/categories.api'

export const CATEGORIES_QUERY_KEY = ['categories'] as const

export function useCategories() {
  return useQuery<CategoryDto[], Error>({
    queryKey: CATEGORIES_QUERY_KEY,
    queryFn: categoriesApi.getAll,
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
