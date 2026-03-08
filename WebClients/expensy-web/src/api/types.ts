// Re-exports from the NSwag-generated client.
// The rest of the app should import from '@/api/types', not from the generated file directly.
export type {
    AuthResponse,
    ProblemDetails,
    RegisterRequest,
    LoginRequest,
    RefreshRequest,
    BudgetDto,
    CategoryDto,
    CreateCategoryRequest,
    UpdateCategoryRequest,
    TransactionDto,
    CreateTransactionRequest,
    UpdateTransactionRequest,
    WalletDto,
    CreateWalletRequest,
    UpdateWalletRequest,
} from './generated/api-client';

// AppException is a class (not a plain interface) so it must be a value export.
export { AppException } from './generated/api-client';
