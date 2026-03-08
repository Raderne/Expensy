import { apiClient } from './client';
import { AuthClient, BudgetsClient, CategoriesClient, TransactionsClient, WalletsClient } from './generated/api-client';

// No /api suffix — generated clients append /api/... to every path themselves.
const BASE_URL = 'http://192.168.1.12:5118';

export const AUTH_API = new AuthClient(BASE_URL, apiClient);
export const WALLETS_API = new WalletsClient(BASE_URL, apiClient);
export const TRANSACTIONS_API = new TransactionsClient(BASE_URL, apiClient);
export const CATEGORIES_API = new CategoriesClient(BASE_URL, apiClient);
export const BUDGETS_API = new BudgetsClient(BASE_URL, apiClient);
