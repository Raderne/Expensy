import React, { useMemo } from 'react'
import { SectionList, StyleSheet, Text, View } from 'react-native'
import { format, isToday, isYesterday, parseISO } from 'date-fns'
import { Colors } from '@/constants/colors'
import { TransactionDto } from '@/api/transactions.api'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Section {
  title: string
  data: TransactionDto[]
}

interface RecentTransactionsListProps {
  transactions: TransactionDto[]
  loading?: boolean
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getSectionTitle(dateStr: string): string {
  const date = parseISO(dateStr)
  if (isToday(date)) return 'TODAY'
  if (isYesterday(date)) return 'YESTERDAY'
  return format(date, 'MMMM d, yyyy')
}

function groupByDate(transactions: TransactionDto[]): Section[] {
  const map = new Map<string, TransactionDto[]>()

  for (const tx of transactions) {
    const key = getSectionTitle(tx.date)
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(tx)
  }

  return Array.from(map.entries()).map(([title, data]) => ({ title, data }))
}

function getCategoryInitial(name: string): string {
  return name.charAt(0).toUpperCase()
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function TransactionItem({ item }: { item: TransactionDto }) {
  const isExpense = item.type === 'expense'
  const amountColor = isExpense ? Colors.dark.danger : Colors.dark.success
  const amountSign = isExpense ? '-' : '+'

  return (
    <View style={styles.item}>
      {/* Icon circle */}
      <View
        style={[
          styles.iconCircle,
          { backgroundColor: item.categoryColor ? `${item.categoryColor}22` : Colors.bg.elevated },
        ]}
      >
        <Text
          style={[
            styles.iconText,
            { color: item.categoryColor || Colors.purple[500] },
          ]}
        >
          {getCategoryInitial(item.categoryName || 'T')}
        </Text>
      </View>

      {/* Details */}
      <View style={styles.details}>
        <Text style={styles.description} numberOfLines={1}>
          {item.description || item.categoryName}
        </Text>
        <Text style={styles.meta}>
          {format(parseISO(item.date), 'h:mm a')}
          {item.paymentMethod ? ` · ${item.paymentMethod}` : ''}
        </Text>
      </View>

      {/* Amount */}
      <Text style={[styles.amount, { color: amountColor }]}>
        {amountSign}${Math.abs(item.amount).toFixed(2)}
      </Text>
    </View>
  )
}

function SectionHeader({ title }: { title: string }) {
  return (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionHeaderText}>{title}</Text>
    </View>
  )
}

function SkeletonItem() {
  return (
    <View style={styles.item}>
      <View style={[styles.iconCircle, styles.skeleton]} />
      <View style={styles.details}>
        <View style={[styles.skeletonLine, { width: '60%' }]} />
        <View style={[styles.skeletonLine, { width: '40%', marginTop: 6 }]} />
      </View>
      <View style={[styles.skeletonLine, { width: 60, alignSelf: 'center' }]} />
    </View>
  )
}

// ─── Main component ───────────────────────────────────────────────────────────

export function RecentTransactionsList({
  transactions,
  loading = false,
}: RecentTransactionsListProps) {
  const sections = useMemo(() => groupByDate(transactions), [transactions])

  if (loading) {
    return (
      <View>
        {[0, 1, 2, 3].map((i) => (
          <SkeletonItem key={i} />
        ))}
      </View>
    )
  }

  if (!loading && transactions.length === 0) {
    return (
      <View style={styles.empty}>
        <Text style={styles.emptyText}>No transactions yet</Text>
        <Text style={styles.emptySubText}>Tap + to add your first expense</Text>
      </View>
    )
  }

  return (
    <SectionList
      sections={sections}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => <TransactionItem item={item} />}
      renderSectionHeader={({ section: { title } }) => (
        <SectionHeader title={title} />
      )}
      scrollEnabled={false}
      stickySectionHeadersEnabled={false}
    />
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    gap: 12,
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  iconText: {
    fontSize: 16,
    fontWeight: '700',
  },
  details: {
    flex: 1,
    gap: 2,
  },
  description: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.dark.text.primary,
  },
  meta: {
    fontSize: 12,
    color: Colors.dark.text.muted,
  },
  amount: {
    fontSize: 14,
    fontWeight: '700',
  },
  sectionHeader: {
    paddingTop: 20,
    paddingBottom: 4,
  },
  sectionHeaderText: {
    fontSize: 11,
    fontWeight: '700',
    color: Colors.dark.text.muted,
    letterSpacing: 1.2,
  },
  empty: {
    alignItems: 'center',
    paddingVertical: 40,
    gap: 6,
  },
  emptyText: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.dark.text.secondary,
  },
  emptySubText: {
    fontSize: 13,
    color: Colors.dark.text.muted,
  },
  skeleton: {
    backgroundColor: Colors.bg.elevated,
    opacity: 0.7,
  },
  skeletonLine: {
    height: 12,
    borderRadius: 6,
    backgroundColor: Colors.bg.elevated,
    opacity: 0.7,
  },
})
