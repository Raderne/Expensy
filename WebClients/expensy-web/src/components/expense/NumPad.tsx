import React from 'react'
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import { Delete } from 'lucide-react-native'
import { Colors } from '@/constants/colors'

interface NumPadProps {
  onDigit: (digit: string) => void
  onDot: () => void
  onBackspace: () => void
}

type KeyConfig =
  | { type: 'digit'; value: string }
  | { type: 'dot' }
  | { type: 'backspace' }

const KEYS: KeyConfig[][] = [
  [
    { type: 'digit', value: '1' },
    { type: 'digit', value: '2' },
    { type: 'digit', value: '3' },
  ],
  [
    { type: 'digit', value: '4' },
    { type: 'digit', value: '5' },
    { type: 'digit', value: '6' },
  ],
  [
    { type: 'digit', value: '7' },
    { type: 'digit', value: '8' },
    { type: 'digit', value: '9' },
  ],
  [
    { type: 'dot' },
    { type: 'digit', value: '0' },
    { type: 'backspace' },
  ],
]

export function NumPad({ onDigit, onDot, onBackspace }: NumPadProps) {
  function handlePress(key: KeyConfig) {
    if (key.type === 'digit') onDigit(key.value)
    else if (key.type === 'dot') onDot()
    else onBackspace()
  }

  return (
    <View style={styles.container}>
      {KEYS.map((row, rowIndex) => (
        <View key={rowIndex} style={styles.row}>
          {row.map((key, colIndex) => (
            <TouchableOpacity
              key={colIndex}
              style={styles.key}
              onPress={() => handlePress(key)}
              activeOpacity={0.6}
              accessibilityRole="button"
              accessibilityLabel={
                key.type === 'digit'
                  ? key.value
                  : key.type === 'dot'
                  ? 'decimal point'
                  : 'backspace'
              }
            >
              {key.type === 'backspace' ? (
                <Delete size={22} color={Colors.dark.text.primary} strokeWidth={1.8} />
              ) : (
                <Text style={styles.keyLabel}>
                  {key.type === 'dot' ? '.' : key.value}
                </Text>
              )}
            </TouchableOpacity>
          ))}
        </View>
      ))}
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    gap: 4,
  },
  row: {
    flexDirection: 'row',
    gap: 4,
  },
  key: {
    flex: 1,
    height: 60,
    borderRadius: 14,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.dark.border.subtle,
  },
  keyLabel: {
    fontSize: 22,
    fontWeight: '500',
    color: Colors.dark.text.primary,
  },
})
