import { apiClient } from './client'

export type TransactionType = 'income' | 'expense'

export interface TransactionDto {
  id: string
  walletId: string
  categoryId: string
  categoryName: string
  categoryColor: string
  categoryIcon: string
  amount: number
  type: TransactionType
  description: string
  date: string
  paymentMethod: string
  createdAt: string
}

export interface PaginatedTransactions {
  items: TransactionDto[]
  total: number
  page: number
  limit: number
}

export interface TransactionsQuery {
  walletId?: string
  page?: number
  limit?: number
}

export interface CreateTransactionPayload {
  walletId: string
  categoryId: string
  amount: number
  type: TransactionType
  description: string
  date: string
  paymentMethod?: string
}

export interface UpdateTransactionPayload {
  categoryId?: string
  amount?: number
  type?: TransactionType
  description?: string
  date?: string
  paymentMethod?: string
}

export const transactionsApi = {
  getAll: (query: TransactionsQuery = {}): Promise<PaginatedTransactions> => {
    const params: Record<string, string | number> = {}
    if (query.walletId) params.walletId = query.walletId
    if (query.page !== undefined) params.page = query.page
    if (query.limit !== undefined) params.limit = query.limit
    return apiClient
      .get<PaginatedTransactions>('/transactions', { params })
      .then((r) => r.data)
  },

  getById: (id: string): Promise<TransactionDto> =>
    apiClient.get<TransactionDto>(`/transactions/${id}`).then((r) => r.data),

  create: (payload: CreateTransactionPayload): Promise<TransactionDto> =>
    apiClient
      .post<TransactionDto>('/transactions', payload)
      .then((r) => r.data),

  update: (
    id: string,
    payload: UpdateTransactionPayload,
  ): Promise<TransactionDto> =>
    apiClient
      .put<TransactionDto>(`/transactions/${id}`, payload)
      .then((r) => r.data),

  remove: (id: string): Promise<void> =>
    apiClient.delete(`/transactions/${id}`).then(() => undefined),
}
