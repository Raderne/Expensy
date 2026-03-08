import { TRANSACTIONS_API } from '@/api/clients'
import type {
  TransactionDto,
  CreateTransactionRequest,
  UpdateTransactionRequest,
} from '@/api/types'

export type { TransactionDto, CreateTransactionRequest, UpdateTransactionRequest }

export const transactionsApi = {
  getAll: (): Promise<TransactionDto[]> => TRANSACTIONS_API.getAll(),
  getById: (id: string): Promise<TransactionDto> => TRANSACTIONS_API.getById(id),
  create: (req: CreateTransactionRequest): Promise<TransactionDto> =>
    TRANSACTIONS_API.create(req),
  update: (id: string, req: UpdateTransactionRequest): Promise<TransactionDto> =>
    TRANSACTIONS_API.update(id, req),
  remove: (id: string): Promise<void> => TRANSACTIONS_API.delete(id),
}
