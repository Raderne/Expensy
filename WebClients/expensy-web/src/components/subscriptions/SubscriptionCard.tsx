import React from 'react'
import { StyleSheet, Text, View } from 'react-native'
import { Colors } from '@/constants/colors'
import type { SubscriptionDto } from '@/api/types'

// ─── Types ────────────────────────────────────────────────────────────────────

interface SubscriptionCardProps {
  subscription: SubscriptionDto
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

function formatRenewalDate(date: Date | undefined): string {
  if (!date) return '—'
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
  }).format(new Date(date))
}

function normalizeCycleName(cycleName: string | undefined): string {
  if (!cycleName) return 'Monthly'
  const name = cycleName.charAt(0).toUpperCase() + cycleName.slice(1).toLowerCase()
  return name
}

// ─── Component ────────────────────────────────────────────────────────────────

export function SubscriptionCard({ subscription }: SubscriptionCardProps) {
  const isActive = subscription.isActive ?? true

  return (
    <View style={[styles.card, !isActive && styles.cardInactive]}>
      {/* Left side: icon + name + category + cycle */}
      <View style={styles.left}>
        <View style={[styles.iconCircle, !isActive && styles.iconCircleInactive]}>
          <Text style={styles.iconText}>
            {subscription.icon ?? '📦'}
          </Text>
        </View>
        <View style={styles.textGroup}>
          <Text
            style={[styles.name, !isActive && styles.nameInactive]}
            numberOfLines={1}
          >
            {subscription.name ?? 'Unnamed'}
          </Text>
          <Text style={styles.meta} numberOfLines={1}>
            {[subscription.categoryName, normalizeCycleName(subscription.cycleName)]
              .filter(Boolean)
              .join(' · ')}
          </Text>
        </View>
      </View>

      {/* Right side: amount + next renewal */}
      <View style={styles.right}>
        <Text style={[styles.amount, !isActive && styles.amountInactive]}>
          {formatCurrency(subscription.amount ?? 0)}
        </Text>
        <Text style={styles.renewal}>
          {formatRenewalDate(subscription.nextRenewal)}
        </Text>
        {!isActive ? (
          <View style={styles.inactiveBadge}>
            <Text style={styles.inactiveBadgeText}>Inactive</Text>
          </View>
        ) : null}
      </View>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  cardInactive: {
    opacity: 0.5,
  },
  left: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  iconCircle: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: Colors.bg.overlay,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconCircleInactive: {
    backgroundColor: Colors.bg.surface,
  },
  iconText: {
    fontSize: 20,
  },
  textGroup: {
    flex: 1,
    gap: 3,
  },
  name: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  nameInactive: {
    color: Colors.dark.text.muted,
  },
  meta: {
    fontSize: 12,
    color: Colors.dark.text.muted,
    fontWeight: '500',
  },
  right: {
    alignItems: 'flex-end',
    gap: 3,
  },
  amount: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  amountInactive: {
    color: Colors.dark.text.muted,
  },
  renewal: {
    fontSize: 12,
    color: Colors.dark.text.muted,
    fontWeight: '500',
  },
  inactiveBadge: {
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 6,
    backgroundColor: Colors.bg.overlay,
    marginTop: 2,
  },
  inactiveBadgeText: {
    fontSize: 10,
    fontWeight: '600',
    color: Colors.dark.text.muted,
  },
})
