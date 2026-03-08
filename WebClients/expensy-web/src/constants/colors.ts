export const Colors = {
  // Primary accent
  purple: { 500: '#B04EFF', 600: '#9333EA', 400: '#C084FC' },
  magenta: { 500: '#D946EF', 400: '#E879F9' },
  teal: { 500: '#14B8A6', 400: '#2DD4BF' },
  mint: '#00E5A0',

  // Semantic
  success: '#22C55E',
  warning: '#F97316',
  danger: '#EF4444',
  info: '#3B82F6',

  // Background layers (dark theme)
  bg: {
    base: '#0A0A0F',
    surface: '#12121A',
    elevated: '#1A1A26',
    overlay: '#22222F',
  },

  // Text
  text: {
    primary: '#F9FAFB',
    secondary: '#9CA3AF',
    muted: '#6B7280',
    inverse: '#0A0A0F',
  },

  // Borders
  border: {
    subtle: '#1F1F2E',
    default: '#2D2D3F',
    strong: '#3D3D52',
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
