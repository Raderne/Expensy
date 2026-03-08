import { useState, useCallback } from 'react'

const MAX_DIGITS = 8
const MAX_DECIMALS = 2

export interface UseNumPadReturn {
  amount: string
  displayAmount: string
  numericAmount: number
  handleDigit: (digit: string) => void
  handleDot: () => void
  handleBackspace: () => void
  handleClear: () => void
}

export function useNumPad(initial = ''): UseNumPadReturn {
  const [amount, setAmount] = useState<string>(initial)

  const handleDigit = useCallback((digit: string) => {
    setAmount((prev) => {
      // Prevent leading multiple zeros: "0" + "0" → stay "0"
      if (prev === '0' && digit === '0') return prev
      // If current is just "0" and a non-zero digit comes in, replace
      if (prev === '0' && digit !== '0') return digit

      const dotIndex = prev.indexOf('.')
      if (dotIndex !== -1) {
        // Already has a decimal — limit decimal places
        const decimals = prev.length - dotIndex - 1
        if (decimals >= MAX_DECIMALS) return prev
      } else {
        // Limit integer part
        const intPart = prev.replace(/^-/, '')
        if (intPart.length >= MAX_DIGITS) return prev
      }
      return prev + digit
    })
  }, [])

  const handleDot = useCallback(() => {
    setAmount((prev) => {
      if (prev.includes('.')) return prev
      if (prev === '') return '0.'
      return prev + '.'
    })
  }, [])

  const handleBackspace = useCallback(() => {
    setAmount((prev) => {
      if (prev.length <= 1) return ''
      return prev.slice(0, -1)
    })
  }, [])

  const handleClear = useCallback(() => {
    setAmount('')
  }, [])

  const numericAmount = parseFloat(amount) || 0

  // Display: show "0" when empty
  const displayAmount = amount === '' ? '0' : amount

  return {
    amount,
    displayAmount,
    numericAmount,
    handleDigit,
    handleDot,
    handleBackspace,
    handleClear,
  }
}
