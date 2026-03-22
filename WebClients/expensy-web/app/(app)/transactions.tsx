import React, { useCallback, useState } from 'react'
import {
  Alert,
  FlatList,
  RefreshControl,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { Plus, Receipt } from 'lucide-react-native'
import { router } from 'expo-router'
import { Colors } from '@/constants/colors'
import { useTransactions, useDeleteTransaction } from '@/hooks/useTransactions'
import {
  TransactionItem,
  TransactionItemSkeleton,
} from '@/components/transactions/TransactionItem'
import type { TransactionDto } from '@/api/types'

// ─── Empty State ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyIconWrap}>
        <Receipt size={40} color={Colors.purple[400]} strokeWidth={1.5} />
      </View>
      <Text style={styles.emptyTitle}>No transactions yet</Text>
      <Text style={styles.emptySubtitle}>
        Tap the + button to record your first expense.
      </Text>
    </View>
  )
}

// ─── Separator ────────────────────────────────────────────────────────────────

function ItemSeparator() {
  return <View style={styles.separator} />
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function TransactionsScreen() {
  const { data: transactions, isLoading, isError, refetch } = useTransactions()
  const deleteTransaction = useDeleteTransaction()
  const [refreshing, setRefreshing] = useState(false)

  const onRefresh = useCallback(async () => {
    setRefreshing(true)
    await refetch()
    setRefreshing(false)
  }, [refetch])

  function handleDelete(id: string) {
    Alert.alert(
      'Delete Transaction',
      'Are you sure you want to delete this transaction? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => deleteTransaction.mutate(id),
        },
      ],
    )
  }

  function renderItem({ item }: { item: TransactionDto }) {
    return <TransactionItem transaction={item} onDelete={handleDelete} />
  }

  function renderListHeader() {
    if (isLoading || !transactions) return null
    const count = transactions.length
    return (
      <View style={styles.listHeader}>
        <Text style={styles.countLabel}>
          {count} {count === 1 ? 'transaction' : 'transactions'}
        </Text>
      </View>
    )
  }

  function renderEmpty() {
    if (isLoading) {
      return (
        <View style={styles.skeletonContainer}>
          {Array.from({ length: 5 }).map((_, i) => (
            <TransactionItemSkeleton key={i} />
          ))}
        </View>
      )
    }
    if (isError) {
      return (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyTitle}>Something went wrong</Text>
          <Text style={styles.emptySubtitle}>
            Could not load transactions. Pull down to retry.
          </Text>
        </View>
      )
    }
    return <EmptyState />
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Transactions</Text>
      </View>

      {/* ── List ── */}
      <FlatList<TransactionDto>
        data={isLoading ? [] : (transactions ?? [])}
        keyExtractor={(item) => item.id ?? Math.random().toString()}
        renderItem={renderItem}
        ListHeaderComponent={renderListHeader}
        ListEmptyComponent={renderEmpty}
        ItemSeparatorComponent={ItemSeparator}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={Colors.purple[500]}
            colors={[Colors.purple[500]]}
          />
        }
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.listContent}
        style={styles.list}
      />

      {/* ── FAB ── */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => router.push('/(app)/add-expense')}
        activeOpacity={0.85}
        accessibilityRole="button"
        accessibilityLabel="Add transaction"
      >
        <Plus size={24} color="#FFFFFF" strokeWidth={2.5} />
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
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 12,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  list: {
    flex: 1,
  },
  listContent: {
    paddingBottom: 100,
  },
  listHeader: {
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  countLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.text.muted,
  },
  separator: {
    height: 1,
    backgroundColor: Colors.border.subtle,
    marginLeft: 70, // aligns with text, skips icon column
  },
  skeletonContainer: {
    paddingTop: 4,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingTop: 80,
    paddingHorizontal: 40,
    gap: 10,
  },
  emptyIconWrap: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
  emptyTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.text.primary,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 13,
    color: Colors.text.muted,
    textAlign: 'center',
    lineHeight: 20,
  },
  fab: {
    position: 'absolute',
    bottom: 80,
    right: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.purple[600],
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: Colors.purple[700],
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 8,
  },
})
