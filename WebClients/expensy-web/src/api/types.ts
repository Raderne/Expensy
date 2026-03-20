// Re-exports from the NSwag-generated client.
// The rest of the app should import from '@/api/types', not from the generated file directly.
export type {
  // Auth
  AuthResponse,
  LoginRequest,
  RefreshRequest,
  // Analytics
  SpendingAnalyticsDto,
  CategorySpendingDto,
  // Budgets
  BudgetDto,
  BudgetSummaryDto,
  BudgetOverallProgressDto,
  BudgetProgressDto,
  BudgetAlertDto,
  CreateBudgetRequest,
  UpdateBudgetRequest,
  // Categories
  CategoryDto,
  CreateCategoryRequest,
  UpdateCategoryRequest,
  // Dashboard
  DashboardSummaryDto,
  DailySpendingDto,
  DailyTransactionGroupDto,
  RecentTransactionDto,
  // Notifications
  NotificationDto,
  NotificationPagedResult,
  // Savings Goals
  SavingsGoalDto,
  MilestoneDto,
  CreateSavingsGoalRequest,
  UpdateSavingsGoalRequest,
  AddFundsRequest,
  CreateMilestoneRequest,
  // Subscriptions
  SubscriptionDto,
  SubscriptionSummaryDto,
  SubscriptionCycleDto,
  CreateSubscriptionRequest,
  UpdateSubscriptionRequest,
  // Transactions
  TransactionDto,
  CreateTransactionRequest,
  UpdateTransactionRequest,
  // Wallets
  WalletDto,
  CreateWalletRequest,
  UpdateWalletRequest,
  // Errors
  ProblemDetails,
} from './generated/api-client';

// AppException is a class (not a plain interface) so it must be a value export.
export { AppException, BudgetStatusEnum } from './generated/api-client';

// ---------------------------------------------------------------------------
// App-specific types not present in the generated client
// ---------------------------------------------------------------------------

/** Register payload — the generated AuthClient does not expose a register
 *  endpoint, so this type is defined here and the call is made directly. */
export interface RegisterRequest {
  email: string;
  password: string;
  userName: string;
}

/** The period granularity for spending analytics queries. */
export type AnalyticsPeriod = 'week' | 'month' | 'year';
