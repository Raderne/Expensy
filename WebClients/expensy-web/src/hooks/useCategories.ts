import { useQuery } from '@tanstack/react-query'
import { categoriesClient } from '@/api/clients'
import type { CategoryDto } from '@/api/types'

export const CATEGORIES_QUERY_KEY = ['categories'] as const

export function useCategories() {
  return useQuery<CategoryDto[], Error>({
    queryKey: CATEGORIES_QUERY_KEY,
    queryFn: () => categoriesClient.getAll(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
