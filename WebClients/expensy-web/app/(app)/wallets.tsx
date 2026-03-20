import React, { useState } from 'react'
import {
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { Plus } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { useDeleteWallet, useWallets } from '@/hooks/useWallets'
import { WalletCard } from '@/components/wallets/WalletCard'
import { CreateWalletModal } from '@/components/wallets/CreateWalletModal'

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(amount)
}

export default function WalletsScreen() {
  const [modalVisible, setModalVisible] = useState(false)
  const { data: wallets = [], isLoading, refetch } = useWallets()
  const { mutate: deleteWallet } = useDeleteWallet()

  const totalBalance = wallets.reduce((sum, w) => sum + (w.balance ?? 0), 0)

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>My Wallets</Text>
        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => setModalVisible(true)}
          accessibilityRole="button"
          accessibilityLabel="Add wallet"
        >
          <Plus size={20} color={Colors.text.primary} strokeWidth={2.5} />
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={isLoading}
            onRefresh={refetch}
            tintColor={Colors.purple[500]}
            colors={[Colors.purple[500]]}
          />
        }
      >
        {/* ── Total balance card ── */}
        {wallets.length > 0 && (
          <View style={styles.totalCard}>
            <Text style={styles.totalLabel}>TOTAL BALANCE</Text>
            <Text style={styles.totalAmount}>{formatCurrency(totalBalance)}</Text>
            <Text style={styles.totalSub}>
              {wallets.length} wallet{wallets.length !== 1 ? 's' : ''}
            </Text>
          </View>
        )}

        {/* ── Wallet list or empty state ── */}
        {wallets.length === 0 && !isLoading ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>💳</Text>
            <Text style={styles.emptyTitle}>No wallets yet</Text>
            <Text style={styles.emptySubtitle}>
              Tap the + button to add your first wallet and start tracking expenses.
            </Text>
            <TouchableOpacity
              style={styles.emptyBtn}
              onPress={() => setModalVisible(true)}
              activeOpacity={0.8}
            >
              <Text style={styles.emptyBtnText}>Add Wallet</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.list}>
            {wallets.map((wallet) => (
              <WalletCard
                key={wallet.id ?? wallet.name}
                wallet={wallet}
                onDelete={(id) => deleteWallet(id)}
              />
            ))}
          </View>
        )}

        <View style={styles.bottomSpacer} />
      </ScrollView>

      <CreateWalletModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
      />
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 12,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  addBtn: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 4,
  },
  totalCard: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
    padding: 20,
    marginBottom: 16,
    alignItems: 'center',
  },
  totalLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: Colors.text.muted,
    letterSpacing: 1,
    marginBottom: 6,
  },
  totalAmount: {
    fontSize: 36,
    fontWeight: '700',
    color: Colors.text.primary,
    fontVariant: ['tabular-nums'],
  },
  totalSub: {
    fontSize: 13,
    color: Colors.text.secondary,
    marginTop: 4,
  },
  list: {
    gap: 10,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingTop: 64,
    gap: 10,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 4,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  emptySubtitle: {
    fontSize: 14,
    color: Colors.text.secondary,
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 24,
  },
  emptyBtn: {
    marginTop: 8,
    backgroundColor: Colors.purple[600],
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
  },
  emptyBtnText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#fff',
  },
  bottomSpacer: {
    height: 24,
  },
})
