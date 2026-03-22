import React, { useEffect, useState } from 'react'
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native'
import { X } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { DatePickerInput } from '@/components/ui/DatePickerInput'
import { useCategories } from '@/hooks/useCategories'
import type { BudgetDto } from '@/api/types'

// ─── Types ────────────────────────────────────────────────────────────────────

// TODO: Replace with NSwag-generated type once regenerated after backend changes
export interface BudgetFormData {
  categoryId: string
  limit: string       // text input, parsed on submit
  period: string
  startDate: string   // YYYY-MM-DD
  endDate: string     // YYYY-MM-DD, optional
}

interface BudgetFormSheetProps {
  visible: boolean
  onClose: () => void
  onSubmit: (data: BudgetFormData) => void
  isSubmitting: boolean
  initial?: BudgetDto | null
}

// ─── Constants ────────────────────────────────────────────────────────────────

const PERIODS = ['Daily', 'Weekly', 'Monthly', 'Yearly'] as const

function todayString(): string {
  const d = new Date()
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/

function buildInitialState(initial?: BudgetDto | null): BudgetFormData {
  if (initial) {
    const startDate = initial.startDate
      ? new Date(initial.startDate).toISOString().slice(0, 10)
      : todayString()
    const endDate = initial.endDate
      ? new Date(initial.endDate).toISOString().slice(0, 10)
      : ''
    return {
      categoryId: initial.categoryId ?? '',
      limit: String(initial.limit ?? ''),
      period: initial.period ?? 'Monthly',
      startDate,
      endDate,
    }
  }
  return {
    categoryId: '',
    limit: '',
    period: 'Monthly',
    startDate: todayString(),
    endDate: '',
  }
}

// ─── Component ────────────────────────────────────────────────────────────────

export function BudgetFormSheet({
  visible,
  onClose,
  onSubmit,
  isSubmitting,
  initial,
}: BudgetFormSheetProps) {
  const { data: categories, isLoading: categoriesLoading } = useCategories()

  const [form, setForm] = useState<BudgetFormData>(() => buildInitialState(initial))
  const [errors, setErrors] = useState<Partial<Record<keyof BudgetFormData, string>>>({})

  // Reset form when sheet opens or initial changes
  useEffect(() => {
    if (visible) {
      setForm(buildInitialState(initial))
      setErrors({})
    }
  }, [visible, initial])

  function setField<K extends keyof BudgetFormData>(key: K, value: BudgetFormData[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
    if (errors[key]) {
      setErrors((prev) => ({ ...prev, [key]: undefined }))
    }
  }

  function validate(): boolean {
    const next: Partial<Record<keyof BudgetFormData, string>> = {}

    if (!form.categoryId) {
      next.categoryId = 'Please select a category.'
    }

    const limitNum = parseFloat(form.limit)
    if (!form.limit || isNaN(limitNum) || limitNum <= 0) {
      next.limit = 'Limit must be a number greater than 0.'
    }

    if (!form.startDate) {
      next.startDate = 'Please select a start date.'
    }

    setErrors(next)
    return Object.keys(next).length === 0
  }

  function handleSubmit() {
    if (!validate()) return
    onSubmit(form)
  }

  const isEdit = Boolean(initial)

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <KeyboardAvoidingView
        style={styles.root}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        {/* ── Sheet header ── */}
        <View style={styles.sheetHeader}>
          <Text style={styles.sheetTitle}>{isEdit ? 'Edit Budget' : 'New Budget'}</Text>
          <TouchableOpacity
            style={styles.closeBtn}
            onPress={onClose}
            activeOpacity={0.7}
            accessibilityRole="button"
            accessibilityLabel="Close form"
          >
            <X size={18} color={Colors.text.secondary} strokeWidth={2} />
          </TouchableOpacity>
        </View>

        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* ── Category chips ── */}
          <View style={styles.fieldGroup}>
            <Text style={styles.label}>Category</Text>
            {categoriesLoading ? (
              <ActivityIndicator color={Colors.purple[500]} style={{ alignSelf: 'flex-start' }} />
            ) : (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.chipsRow}
              >
                {(categories ?? []).map((cat) => {
                  const selected = form.categoryId === cat.id
                  return (
                    <Pressable
                      key={cat.id}
                      style={[styles.chip, selected && styles.chipSelected]}
                      onPress={() => setField('categoryId', cat.id ?? '')}
                      accessibilityRole="button"
                      accessibilityLabel={`Select ${cat.name} category`}
                    >
                      <Text style={styles.chipIcon}>{cat.icon ?? '📦'}</Text>
                      <Text style={[styles.chipText, selected && styles.chipTextSelected]}>
                        {cat.name}
                      </Text>
                    </Pressable>
                  )
                })}
              </ScrollView>
            )}
            {errors.categoryId ? (
              <Text style={styles.errorText}>{errors.categoryId}</Text>
            ) : null}
          </View>

          {/* ── Limit ── */}
          <View style={styles.fieldGroup}>
            <Text style={styles.label}>Monthly Limit ($)</Text>
            <TextInput
              style={[styles.input, errors.limit ? styles.inputError : null]}
              value={form.limit}
              onChangeText={(v) => setField('limit', v)}
              keyboardType="decimal-pad"
              placeholder="e.g. 500"
              placeholderTextColor={Colors.text.muted}
              returnKeyType="done"
              accessibilityLabel="Budget limit amount"
            />
            {errors.limit ? <Text style={styles.errorText}>{errors.limit}</Text> : null}
          </View>

          {/* ── Period pills ── */}
          <View style={styles.fieldGroup}>
            <Text style={styles.label}>Period</Text>
            <View style={styles.pillRow}>
              {PERIODS.map((p) => {
                const selected = form.period.toLowerCase() === p.toLowerCase()
                return (
                  <TouchableOpacity
                    key={p}
                    style={[styles.pill, selected && styles.pillSelected]}
                    onPress={() => setField('period', p.toLowerCase())}
                    activeOpacity={0.7}
                    accessibilityRole="button"
                    accessibilityLabel={`${p} period`}
                  >
                    <Text style={[styles.pillText, selected && styles.pillTextSelected]}>
                      {p}
                    </Text>
                  </TouchableOpacity>
                )
              })}
            </View>
          </View>

          {/* ── Start Date ── */}
          <DatePickerInput
            label="Start Date"
            value={form.startDate}
            onChange={(v) => setField('startDate', v)}
            error={errors.startDate}
            accessibilityLabel="Budget start date"
          />

          {/* ── End Date (optional) ── */}
          <DatePickerInput
            label="End Date"
            value={form.endDate}
            onChange={(v) => setField('endDate', v)}
            error={errors.endDate}
            optional
            placeholder="No end date"
            accessibilityLabel="Budget end date"
          />
        </ScrollView>

        {/* ── Submit ── */}
        <View style={styles.footer}>
          <TouchableOpacity
            style={[styles.submitBtn, isSubmitting && styles.submitBtnDisabled]}
            onPress={handleSubmit}
            disabled={isSubmitting}
            activeOpacity={0.8}
            accessibilityRole="button"
            accessibilityLabel={isEdit ? 'Update budget' : 'Create budget'}
          >
            {isSubmitting ? (
              <ActivityIndicator color="#FFFFFF" />
            ) : (
              <Text style={styles.submitBtnText}>
                {isEdit ? 'Update Budget' : 'Create Budget'}
              </Text>
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  sheetHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border.subtle,
  },
  sheetTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  closeBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 24,
    gap: 20,
  },
  fieldGroup: {
    gap: 8,
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.text.secondary,
    letterSpacing: 0.3,
  },
  optionalLabel: {
    fontSize: 12,
    fontWeight: '400',
    color: Colors.text.muted,
  },
  input: {
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    color: Colors.text.primary,
  },
  inputError: {
    borderColor: Colors.danger,
  },
  errorText: {
    fontSize: 12,
    color: Colors.danger,
  },
  chipsRow: {
    flexDirection: 'row',
    gap: 8,
    paddingVertical: 2,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
  },
  chipSelected: {
    backgroundColor: `${Colors.purple[600]}22`,
    borderColor: Colors.purple[500],
  },
  chipIcon: {
    fontSize: 14,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.text.secondary,
  },
  chipTextSelected: {
    color: Colors.purple[400],
  },
  pillRow: {
    flexDirection: 'row',
    gap: 8,
  },
  pill: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
    alignItems: 'center',
  },
  pillSelected: {
    backgroundColor: `${Colors.purple[600]}22`,
    borderColor: Colors.purple[500],
  },
  pillText: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.text.secondary,
  },
  pillTextSelected: {
    color: Colors.purple[400],
  },
  footer: {
    paddingHorizontal: 20,
    paddingBottom: Platform.OS === 'ios' ? 36 : 24,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: Colors.border.subtle,
  },
  submitBtn: {
    backgroundColor: Colors.purple[600],
    borderRadius: 12,
    paddingVertical: 15,
    alignItems: 'center',
  },
  submitBtnDisabled: {
    opacity: 0.6,
  },
  submitBtnText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#FFFFFF',
  },
})
