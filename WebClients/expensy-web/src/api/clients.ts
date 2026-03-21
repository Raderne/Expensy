import { nswagAxios, BASE_URL } from './client';
import {
  AnalyticsClient,
  AuthClient,
  BudgetsClient,
  CategoriesClient,
  DashboardClient,
  NotificationsClient,
  ProfileClient,
  SavingsGoalsClient,
  SettingsClient,
  SubscriptionsClient,
  TransactionsClient,
  WalletsClient,
} from './generated/api-client';

export const analyticsClient = new AnalyticsClient(BASE_URL, nswagAxios);
export const authClient = new AuthClient(BASE_URL, nswagAxios);
export const budgetsClient = new BudgetsClient(BASE_URL, nswagAxios);
export const categoriesClient = new CategoriesClient(BASE_URL, nswagAxios);
export const dashboardClient = new DashboardClient(BASE_URL, nswagAxios);
export const notificationsClient = new NotificationsClient(BASE_URL, nswagAxios);
export const profileClient = new ProfileClient(BASE_URL, nswagAxios);
export const savingsGoalsClient = new SavingsGoalsClient(BASE_URL, nswagAxios);
export const settingsClient = new SettingsClient(BASE_URL, nswagAxios);
export const subscriptionsClient = new SubscriptionsClient(BASE_URL, nswagAxios);
export const transactionsClient = new TransactionsClient(BASE_URL, nswagAxios);
export const walletsClient = new WalletsClient(BASE_URL, nswagAxios);
