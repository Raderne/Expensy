import React from 'react'
import { Alert, StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import { Colors } from '@/constants/colors'
import type { WalletDto } from '@/api/types'

interface WalletCardProps {
  wallet: WalletDto
  onDelete: (id: string) => void
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(amount)
}

export function WalletCard({ wallet, onDelete }: WalletCardProps) {
  const handleLongPress = () => {
    Alert.alert(
      'Delete Wallet',
      `Remove "${wallet.name ?? 'this wallet'}"? This cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => wallet.id && onDelete(wallet.id),
        },
      ],
    )
  }

  return (
    <TouchableOpacity
      style={styles.card}
      onLongPress={handleLongPress}
      activeOpacity={0.75}
      accessibilityRole="button"
      accessibilityLabel={`${wallet.name ?? 'Wallet'}, balance ${formatCurrency(wallet.balance ?? 0)}. Long press to delete.`}
    >
      <View style={styles.left}>
        <View style={styles.iconCircle}>
          <Text style={styles.icon}>{wallet.icon ?? '💳'}</Text>
        </View>
        <Text style={styles.name} numberOfLines={1}>{wallet.name ?? '—'}</Text>
      </View>
      <Text style={styles.balance}>{formatCurrency(wallet.balance ?? 0)}</Text>
    </TouchableOpacity>
  )
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.bg.overlay,
    alignItems: 'center',
    justifyContent: 'center',
  },
  icon: {
    fontSize: 22,
  },
  name: {
    flex: 1,
    fontSize: 15,
    fontWeight: '600',
    color: Colors.text.primary,
  },
  balance: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.text.primary,
    fontVariant: ['tabular-nums'],
  },
})
