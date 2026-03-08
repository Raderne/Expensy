import React from 'react'
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import { Wallet, ChevronDown } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { WalletDto } from '@/api/wallets.api'

interface WalletSelectorProps {
  wallets: WalletDto[]
  selectedWalletId: string | null
  onSelect: (wallet: WalletDto) => void
  loading?: boolean
}

export function WalletSelector({
  wallets,
  selectedWalletId,
  onSelect,
  loading = false,
}: WalletSelectorProps) {
  const selected = wallets.find((w) => w.id === selectedWalletId) ?? wallets[0]

  // Simple inline picker — cycles through wallets on tap for now
  // (a full modal picker can be added later)
  function handlePress() {
    if (wallets.length === 0) return
    const currentIndex = wallets.findIndex((w) => w.id === selected?.id)
    const nextIndex = (currentIndex + 1) % wallets.length
    onSelect(wallets[nextIndex])
  }

  return (
    <TouchableOpacity
      style={styles.container}
      onPress={handlePress}
      activeOpacity={0.75}
      accessibilityRole="button"
      accessibilityLabel="Select wallet"
      disabled={loading || wallets.length === 0}
    >
      <View style={styles.iconWrap}>
        <Wallet size={16} color={Colors.purple[500]} strokeWidth={2} />
      </View>
      <Text style={styles.label} numberOfLines={1}>
        {loading
          ? 'Loading wallets…'
          : selected
          ? selected.name
          : 'Select wallet'}
      </Text>
      {selected && (
        <Text style={styles.balance}>
          {selected.currency} {selected.balance.toFixed(2)}
        </Text>
      )}
      <ChevronDown size={16} color={Colors.dark.text.muted} strokeWidth={2} />
    </TouchableOpacity>
  )
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: Colors.dark.border.default,
    gap: 10,
  },
  iconWrap: {
    width: 32,
    height: 32,
    borderRadius: 10,
    backgroundColor: 'rgba(176,78,255,0.12)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    flex: 1,
    fontSize: 14,
    fontWeight: '600',
    color: Colors.dark.text.primary,
  },
  balance: {
    fontSize: 12,
    color: Colors.dark.text.muted,
    marginRight: 2,
  },
})
