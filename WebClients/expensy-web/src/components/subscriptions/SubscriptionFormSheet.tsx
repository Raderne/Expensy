import React, { useEffect, useState } from 'react'
import {
  ActivityIndicator,
  Modal,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native'
import { Colors } from '@/constants/colors'
import { useSubscriptionCycles } from '@/hooks/useSubscriptions'
import type { SubscriptionDto } from '@/api/types'

// ─── Types ────────────────────────────────────────────────────────────────────

// TODO: Replace with NSwag-generated type once regenerated after Phase 6 backend changes
export interface SubscriptionFormData {
  name: string
  icon: string
  amount: string   // kept as string for text input, parsed on submit
  cycleId: string
  categoryId: string
  startDate: string  // ISO date string YYYY-MM-DD
  isActive: boolean
}

interface SubscriptionFormSheetProps {
  visible: boolean
  onClose: () => void
  onSubmit: (data: SubscriptionFormData) => void
  isSubmitting: boolean
  initial?: SubscriptionDto | null
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function todayIso(): string {
  const d = new Date()
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

function buildInitialFormData(sub: SubscriptionDto | null | undefined): SubscriptionFormData {
  if (!sub) {
    return {
      name: '',
      icon: '',
      amount: '',
      cycleId: '',
      categoryId: '',
      startDate: todayIso(),
      isActive: true,
    }
  }

  // Derive the start date from nextRenewal if present (best available field)
  let startDate = todayIso()
  if (sub.nextRenewal) {
    const d = new Date(sub.nextRenewal)
    const yyyy = d.getFullYear()
    const mm = String(d.getMonth() + 1).padStart(2, '0')
    const dd = String(d.getDate()).padStart(2, '0')
    startDate = `${yyyy}-${mm}-${dd}`
  }

  return {
    name: sub.name ?? '',
    icon: sub.icon ?? '',
    amount: sub.amount != null ? String(sub.amount) : '',
    cycleId: '',       // SubscriptionDto does not expose cycleId, only cycleName
    categoryId: sub.categoryId ?? '',
    startDate,
    isActive: sub.isActive ?? true,
  }
}

// ─── Validation ───────────────────────────────────────────────────────────────

interface FormErrors {
  name?: string
  icon?: string
  amount?: string
  cycleId?: string
  startDate?: string
}

function validate(data: SubscriptionFormData): FormErrors {
  const errors: FormErrors = {}

  const name = data.name.trim()
  if (name.length < 2) {
    errors.name = 'Name must be at least 2 characters.'
  } else if (name.length > 50) {
    errors.name = 'Name must be 50 characters or fewer.'
  }

  if (data.icon.trim().length > 0 && [...data.icon.trim()].length > 1) {
    errors.icon = 'Please enter a single emoji or character.'
  }

  const parsed = parseFloat(data.amount)
  if (isNaN(parsed) || parsed <= 0) {
    errors.amount = 'Amount must be greater than 0.'
  }

  if (!data.cycleId) {
    errors.cycleId = 'Please select a billing cycle.'
  }

  if (!data.startDate.match(/^\d{4}-\d{2}-\d{2}$/)) {
    errors.startDate = 'Enter a valid date in YYYY-MM-DD format.'
  }

  return errors
}

// ─── Skeleton Pill ────────────────────────────────────────────────────────────

function CycleSkeleton() {
  return (
    <View style={styles.cycleRow}>
      {[1, 2, 3, 4].map((i) => (
        <View key={i} style={styles.cycleSkeleton} />
      ))}
    </View>
  )
}

// ─── Component ────────────────────────────────────────────────────────────────

export function SubscriptionFormSheet({
  visible,
  onClose,
  onSubmit,
  isSubmitting,
  initial,
}: SubscriptionFormSheetProps) {
  const isEditMode = initial != null

  const [form, setForm] = useState<SubscriptionFormData>(() =>
    buildInitialFormData(initial),
  )
  const [errors, setErrors] = useState<FormErrors>({})

  const { data: cycles, isLoading: cyclesLoading } = useSubscriptionCycles()

  // Re-populate form when `initial` changes (e.g., user taps edit on a different item)
  useEffect(() => {
    if (visible) {
      const next = buildInitialFormData(initial)

      // When editing, try to match the cycle by name to pick the right cycleId
      if (initial?.cycleName && cycles && cycles.length > 0) {
        const matched = cycles.find(
          (c) =>
            c.name?.toLowerCase() === initial.cycleName?.toLowerCase() ||
            c.code?.toLowerCase() === initial.cycleName?.toLowerCase(),
        )
        if (matched?.id) {
          next.cycleId = matched.id
        }
      }

      // Default cycleId to "monthly" when creating if cycles are already loaded
      if (!isEditMode && cycles && cycles.length > 0 && !next.cycleId) {
        const monthly = cycles.find(
          (c) => c.name?.toLowerCase() === 'monthly' || c.code?.toLowerCase() === 'monthly',
        )
        next.cycleId = monthly?.id ?? cycles[0]?.id ?? ''
      }

      setForm(next)
      setErrors({})
    }
  }, [visible, initial, cycles, isEditMode])

  // When cycles finish loading and no cycleId is selected yet, default to Monthly
  useEffect(() => {
    if (cycles && cycles.length > 0 && !form.cycleId) {
      const monthly = cycles.find(
        (c) => c.name?.toLowerCase() === 'monthly' || c.code?.toLowerCase() === 'monthly',
      )
      setForm((prev) => ({
        ...prev,
        cycleId: monthly?.id ?? cycles[0]?.id ?? '',
      }))
    }
  }, [cycles]) // intentionally omits form.cycleId to avoid loop — only run when cycles arrive

  function setField<K extends keyof SubscriptionFormData>(
    key: K,
    value: SubscriptionFormData[K],
  ) {
    setForm((prev) => ({ ...prev, [key]: value }))
    // Clear the error for this field on change
    if (errors[key as keyof FormErrors]) {
      setErrors((prev) => ({ ...prev, [key]: undefined }))
    }
  }

  function handleSubmit() {
    const validationErrors = validate(form)
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors)
      return
    }
    onSubmit(form)
  }

  function handleClose() {
    if (!isSubmitting) {
      onClose()
    }
  }

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={handleClose}
    >
      <View style={styles.overlay}>
        <View style={styles.sheet}>
          {/* Drag handle */}
          <View style={styles.handle} />

          <ScrollView
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Title */}
            <Text style={styles.title}>
              {isEditMode ? 'Edit Subscription' : 'Add Subscription'}
            </Text>

            {/* ── Name ── */}
            <Text style={styles.label}>Name</Text>
            <TextInput
              style={[styles.input, errors.name ? styles.inputError : null]}
              placeholder="e.g. Netflix"
              placeholderTextColor={Colors.text.muted}
              value={form.name}
              onChangeText={(t) => setField('name', t)}
              autoCapitalize="words"
              returnKeyType="next"
              editable={!isSubmitting}
            />
            {errors.name ? <Text style={styles.errorText}>{errors.name}</Text> : null}

            {/* ── Icon ── */}
            <Text style={styles.label}>Emoji icon (optional)</Text>
            <TextInput
              style={[styles.input, errors.icon ? styles.inputError : null]}
              placeholder="e.g. 📺"
              placeholderTextColor={Colors.text.muted}
              value={form.icon}
              onChangeText={(t) => setField('icon', t)}
              autoCapitalize="none"
              returnKeyType="next"
              editable={!isSubmitting}
            />
            {errors.icon ? <Text style={styles.errorText}>{errors.icon}</Text> : null}

            {/* ── Amount ── */}
            <Text style={styles.label}>Amount</Text>
            <TextInput
              style={[styles.input, errors.amount ? styles.inputError : null]}
              placeholder="0.00"
              placeholderTextColor={Colors.text.muted}
              value={form.amount}
              onChangeText={(t) => setField('amount', t)}
              keyboardType="decimal-pad"
              returnKeyType="next"
              editable={!isSubmitting}
            />
            {errors.amount ? <Text style={styles.errorText}>{errors.amount}</Text> : null}

            {/* ── Billing Cycle ── */}
            <Text style={styles.label}>Billing cycle</Text>
            {cyclesLoading ? (
              <CycleSkeleton />
            ) : (
              <View style={styles.cycleRow}>
                {(cycles ?? []).map((cycle) => {
                  const isSelected = form.cycleId === cycle.id
                  return (
                    <TouchableOpacity
                      key={cycle.id}
                      style={[styles.cyclePill, isSelected && styles.cyclePillActive]}
                      onPress={() => setField('cycleId', cycle.id ?? '')}
                      activeOpacity={0.75}
                      disabled={isSubmitting}
                      accessibilityRole="button"
                      accessibilityState={{ selected: isSelected }}
                      accessibilityLabel={`${cycle.name} billing cycle`}
                    >
                      <Text
                        style={[styles.cyclePillText, isSelected && styles.cyclePillTextActive]}
                      >
                        {cycle.name}
                      </Text>
                    </TouchableOpacity>
                  )
                })}
              </View>
            )}
            {errors.cycleId ? (
              <Text style={styles.errorText}>{errors.cycleId}</Text>
            ) : null}

            {/* ── Start Date ── */}
            <Text style={styles.label}>Start date (YYYY-MM-DD)</Text>
            <TextInput
              style={[styles.input, errors.startDate ? styles.inputError : null]}
              placeholder={todayIso()}
              placeholderTextColor={Colors.text.muted}
              value={form.startDate}
              onChangeText={(t) => setField('startDate', t)}
              keyboardType="numbers-and-punctuation"
              returnKeyType="done"
              editable={!isSubmitting}
            />
            {errors.startDate ? (
              <Text style={styles.errorText}>{errors.startDate}</Text>
            ) : null}

            {/* ── Active toggle ── */}
            <View style={styles.toggleRow}>
              <View style={styles.toggleTextGroup}>
                <Text style={styles.toggleLabel}>Active</Text>
                <Text style={styles.toggleHint}>
                  Inactive subscriptions are excluded from totals.
                </Text>
              </View>
              <Switch
                value={form.isActive}
                onValueChange={(v) => setField('isActive', v)}
                trackColor={{ false: Colors.border.default, true: Colors.purple[600] }}
                thumbColor={form.isActive ? Colors.purple[400] : Colors.text.muted}
                disabled={isSubmitting}
              />
            </View>

            {/* ── Submit ── */}
            <TouchableOpacity
              style={[styles.submitBtn, isSubmitting && styles.submitBtnDisabled]}
              onPress={handleSubmit}
              disabled={isSubmitting}
              activeOpacity={0.8}
              accessibilityRole="button"
              accessibilityLabel={isEditMode ? 'Save Changes' : 'Add Subscription'}
            >
              {isSubmitting ? (
                <ActivityIndicator color="#fff" size="small" />
              ) : (
                <Text style={styles.submitBtnText}>
                  {isEditMode ? 'Save Changes' : 'Add Subscription'}
                </Text>
              )}
            </TouchableOpacity>

            {/* ── Cancel ── */}
            <TouchableOpacity
              style={styles.cancelBtn}
              onPress={handleClose}
              disabled={isSubmitting}
              accessibilityRole="button"
              accessibilityLabel="Cancel"
            >
              <Text style={styles.cancelBtnText}>Cancel</Text>
            </TouchableOpacity>

            <View style={styles.bottomPad} />
          </ScrollView>
        </View>
      </View>
    </Modal>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: Colors.bg.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingHorizontal: 20,
    paddingTop: 12,
    maxHeight: '90%',
  },
  handle: {
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: Colors.border.default,
    alignSelf: 'center',
    marginBottom: 20,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    marginBottom: 20,
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.dark.text.secondary,
    marginBottom: 6,
    marginTop: 12,
  },
  input: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: Colors.border.default,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    color: Colors.dark.text.primary,
  },
  inputError: {
    borderColor: Colors.danger,
  },
  errorText: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.danger,
  },
  // Cycle pill row
  cycleRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 4,
  },
  cyclePill: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
  },
  cyclePillActive: {
    backgroundColor: Colors.purple[700],
    borderColor: Colors.purple[500],
  },
  cyclePillText: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.dark.text.secondary,
  },
  cyclePillTextActive: {
    color: '#FFFFFF',
  },
  cycleSkeleton: {
    width: 72,
    height: 36,
    borderRadius: 20,
    backgroundColor: Colors.bg.elevated,
  },
  // Active toggle
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
    marginTop: 8,
    borderTopWidth: 1,
    borderTopColor: Colors.border.subtle,
  },
  toggleTextGroup: {
    flex: 1,
    marginRight: 12,
    gap: 2,
  },
  toggleLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.dark.text.primary,
  },
  toggleHint: {
    fontSize: 12,
    color: Colors.dark.text.muted,
  },
  // Submit / Cancel
  submitBtn: {
    backgroundColor: Colors.purple[600],
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 8,
  },
  submitBtnDisabled: {
    opacity: 0.6,
  },
  submitBtnText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  cancelBtn: {
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 4,
  },
  cancelBtnText: {
    fontSize: 15,
    fontWeight: '500',
    color: Colors.dark.text.secondary,
  },
  bottomPad: {
    height: 20,
  },
})
