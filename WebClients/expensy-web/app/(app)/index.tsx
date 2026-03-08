import React, { useCallback } from 'react'
import {
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { router } from 'expo-router'
import { Bell, Plus } from 'lucide-react-native'
import { useAuthStore } from '@/store/auth.store'
import { Colors } from '@/constants/colors'
import { useWallets } from '@/hooks/useWallets'
import { useTransactions } from '@/hooks/useTransactions'
import { BalanceCard } from '@/components/dashboard/BalanceCard'
import { WeeklySpendingChart } from '@/components/dashboard/WeeklySpendingChart'
import { RecentTransactionsList } from '@/components/dashboard/RecentTransactionsList'
import { Card } from '@/components/ui/Card'

// ─── Avatar / Initials helper ─────────────────────────────────────────────────

function getInitials(email: string): string {
  const name = email.split('@')[0]
  const parts = name.split(/[._-]/)
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase()
  }
  return name.slice(0, 2).toUpperCase()
}

// ─── Derived totals ────────────────────────────────────────────────────────────

function getTotalBalance(balances: number[]): number {
  return balances.reduce((sum, b) => sum + b, 0)
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

export default function DashboardScreen() {
  const { user } = useAuthStore()

  const {
    data: wallets,
    isLoading: walletsLoading,
    refetch: refetchWallets,
  } = useWallets()

  const {
    data: txData,
    isLoading: txLoading,
    refetch: refetchTx,
  } = useTransactions({ page: 1, limit: 30 })

  const isRefreshing = walletsLoading || txLoading

  const onRefresh = useCallback(() => {
    refetchWallets()
    refetchTx()
  }, [refetchWallets, refetchTx])

  const totalBalance = wallets ? getTotalBalance(wallets.map((w) => w.balance)) : 0
  const transactions = txData?.items ?? []

  const initials = user ? getInitials(user.email) : 'ME'
  const displayName = user?.email.split('@')[0] ?? 'there'

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          {/* Avatar */}
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{initials}</Text>
          </View>
          <View style={styles.greetingGroup}>
            <Text style={styles.greetingLabel}>WELCOME BACK</Text>
            <Text style={styles.greetingName} numberOfLines={1}>
              {displayName}
            </Text>
          </View>
        </View>

        {/* Notification bell */}
        <TouchableOpacity
          style={styles.bellButton}
          activeOpacity={0.75}
          accessibilityRole="button"
          accessibilityLabel="Notifications"
        >
          <Bell size={22} color={Colors.dark.text.primary} strokeWidth={1.8} />
          {/* Pulse badge */}
          <View style={styles.badge} />
        </TouchableOpacity>
      </View>

      {/* ── Scrollable content ── */}
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={onRefresh}
            tintColor={Colors.purple[500]}
            colors={[Colors.purple[500]]}
          />
        }
      >
        {/* Balance card */}
        <BalanceCard
          balance={totalBalance}
          loading={walletsLoading}
          label="Total Balance"
        />

        {/* Weekly spending */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Weekly Spending</Text>
            <TouchableOpacity activeOpacity={0.7}>
              <Text style={styles.viewAll}>View All</Text>
            </TouchableOpacity>
          </View>
          <Card>
            <WeeklySpendingChart loading={txLoading} />
          </Card>
        </View>

        {/* Recent transactions */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Recent Transactions</Text>
            <TouchableOpacity
              activeOpacity={0.7}
              onPress={() => router.push('/(app)/transactions')}
            >
              <Text style={styles.viewAll}>View All</Text>
            </TouchableOpacity>
          </View>
          <Card>
            <RecentTransactionsList
              transactions={transactions}
              loading={txLoading}
            />
          </Card>
        </View>

        {/* Bottom padding so FAB doesn't overlap last item */}
        <View style={{ height: 100 }} />
      </ScrollView>

      {/* ── FAB ── */}
      <TouchableOpacity
        style={styles.fab}
        activeOpacity={0.85}
        onPress={() => router.push('/(app)/add-expense')}
        accessibilityRole="button"
        accessibilityLabel="Add new expense"
      >
        <Plus size={26} color="#FFFFFF" strokeWidth={2.5} />
      </TouchableOpacity>
    </SafeAreaView>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.purple[600],
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  greetingGroup: {
    gap: 2,
  },
  greetingLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: Colors.dark.text.muted,
    letterSpacing: 1.2,
  },
  greetingName: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    textTransform: 'capitalize',
  },
  bellButton: {
    position: 'relative',
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.dark.border.subtle,
  },
  badge: {
    position: 'absolute',
    top: 9,
    right: 9,
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.purple[500],
    borderWidth: 1.5,
    borderColor: Colors.bg.base,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    gap: 20,
    paddingTop: 4,
    paddingBottom: 20,
  },
  section: {
    paddingHorizontal: 16,
    gap: 10,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  viewAll: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.purple[500],
  },
  fab: {
    position: 'absolute',
    bottom: 90,    // sits above the tab bar (~80px) with 10px gap
    right: 20,
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: Colors.purple[600],
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: Colors.purple[500],
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 12,
    elevation: 8,
  },
})
