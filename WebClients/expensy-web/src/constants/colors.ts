export const Colors = {
  // ── Light / brand tokens (legacy – used by auth screens & shared UI) ──────
  primary: {
    500: '#2563EB',
    600: '#1D4ED8',
    700: '#1E40AF',
  },
  surface: {
    0: '#FFFFFF',
    50: '#F8FAFC',
    100: '#F1F5F9',
    200: '#E2E8F0',
    800: '#1E293B',
    900: '#0F172A',
  },
  success: '#22C55E',
  error: '#EF4444',
  warning: '#F59E0B',
  income: '#22C55E',
  expense: '#EF4444',
  text: {
    primary: '#0F172A',
    secondary: '#64748B',
    inverse: '#FFFFFF',
  },

  // ── Dark app shell tokens ─────────────────────────────────────────────────
  bg: {
    base: '#0A0A0F',
    surface: '#12121A',
    elevated: '#1A1A26',
  },
  purple: {
    300: '#D8B4FE',
    400: '#C084FC',
    500: '#B04EFF',
    600: '#9333EA',
    700: '#7C3AED',
    900: '#2E1065',
  },
  mint: {
    500: '#00E5A0',
    600: '#00C87F',
  },
  dark: {
    text: {
      primary: '#F9FAFB',
      secondary: '#9CA3AF',
      muted: '#6B7280',
    },
    border: {
      default: '#2D2D3F',
      subtle: '#1F1F2E',
    },
    danger: '#EF4444',
    success: '#22C55E',
    warning: '#F97316',
  },
} as const
