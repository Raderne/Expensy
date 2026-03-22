import React, { useCallback, useEffect, useState } from 'react'
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Modal,
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { PiggyBank, Plus, X } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { DatePickerInput } from '@/components/ui/DatePickerInput'
import {
  useSavingsGoals,
  useCreateSavingsGoal,
  useDeleteSavingsGoal,
  useAddFunds,
} from '@/hooks/useSavingsGoals'
import { GoalCard, GoalCardSkeleton } from '@/components/savings/GoalCard'

// ─── Types ────────────────────────────────────────────────────────────────────

// TODO: Replace with NSwag-generated type once regenerated after backend changes
interface GoalFormData {
  name: string
  targetAmount: string  // text input, parsed on submit
  targetDate: string    // YYYY-MM-DD
  icon: string          // single emoji char
}

interface FundsFormData {
  amount: string  // text input, parsed on submit
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function todayString(): string {
  const d = new Date()
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/

const DEFAULT_GOAL_FORM: GoalFormData = {
  name: '',
  targetAmount: '',
  targetDate: todayString(),
  icon: '🎯',
}

// ─── Empty State ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyIconWrap}>
        <PiggyBank size={40} color={Colors.purple[400]} strokeWidth={1.5} />
      </View>
      <Text style={styles.emptyTitle}>No savings goals yet</Text>
      <Text style={styles.emptySubtitle}>
        Create a savings goal to start tracking your progress toward something meaningful.
      </Text>
    </View>
  )
}

// ─── Error State ──────────────────────────────────────────────────────────────

function ErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <View style={styles.emptyContainer}>
      <Text style={styles.emptyTitle}>Something went wrong</Text>
      <Text style={styles.emptySubtitle}>
        Could not load your savings goals. Please try again.
      </Text>
      <TouchableOpacity
        style={styles.retryButton}
        onPress={onRetry}
        activeOpacity={0.75}
        accessibilityRole="button"
        accessibilityLabel="Retry loading savings goals"
      >
        <Text style={styles.retryText}>Retry</Text>
      </TouchableOpacity>
    </View>
  )
}

// ─── SavingsGoalFormSheet ─────────────────────────────────────────────────────

interface SavingsGoalFormSheetProps {
  visible: boolean
  onClose: () => void
  onSubmit: (data: GoalFormData) => void
  isSubmitting: boolean
}

function SavingsGoalFormSheet({
  visible,
  onClose,
  onSubmit,
  isSubmitting,
}: SavingsGoalFormSheetProps) {
  const [form, setForm] = useState<GoalFormData>(DEFAULT_GOAL_FORM)
  const [errors, setErrors] = useState<Partial<Record<keyof GoalFormData, string>>>({})

  useEffect(() => {
    if (visible) {
      setForm(DEFAULT_GOAL_FORM)
      setErrors({})
    }
  }, [visible])

  function setField<K extends keyof GoalFormData>(key: K, value: string) {
    setForm((prev) => ({ ...prev, [key]: value }))
    if (errors[key]) {
      setErrors((prev) => ({ ...prev, [key]: undefined }))
    }
  }

  function validate(): boolean {
    const next: Partial<Record<keyof GoalFormData, string>> = {}

    const name = form.name.trim()
    if (name.length < 2 || name.length > 50) {
      next.name = 'Name must be between 2 and 50 characters.'
    }

    const amount = parseFloat(form.targetAmount)
    if (!form.targetAmount || isNaN(amount) || amount <= 0) {
      next.targetAmount = 'Target amount must be greater than 0.'
    }

    if (!form.targetDate) {
      next.targetDate = 'Please select a target date.'
    }

    setErrors(next)
    return Object.keys(next).length === 0
  }

  function handleSubmit() {
    if (!validate()) return
    onSubmit(form)
  }

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <KeyboardAvoidingView
        style={sheetStyles.root}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        {/* Header */}
        <View style={sheetStyles.header}>
          <Text style={sheetStyles.title}>New Savings Goal</Text>
          <TouchableOpacity
            style={sheetStyles.closeBtn}
            onPress={onClose}
            activeOpacity={0.7}
            accessibilityRole="button"
            accessibilityLabel="Close form"
          >
            <X size={18} color={Colors.text.secondary} strokeWidth={2} />
          </TouchableOpacity>
        </View>

        <ScrollView
          style={sheetStyles.scroll}
          contentContainerStyle={sheetStyles.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Name */}
          <View style={sheetStyles.fieldGroup}>
            <Text style={sheetStyles.label}>Goal Name</Text>
            <TextInput
              style={[sheetStyles.input, errors.name ? sheetStyles.inputError : null]}
              value={form.name}
              onChangeText={(v) => setField('name', v)}
              placeholder="e.g. Emergency Fund"
              placeholderTextColor={Colors.text.muted}
              returnKeyType="next"
              maxLength={50}
              accessibilityLabel="Goal name"
            />
            {errors.name ? <Text style={sheetStyles.errorText}>{errors.name}</Text> : null}
          </View>

          {/* Target Amount */}
          <View style={sheetStyles.fieldGroup}>
            <Text style={sheetStyles.label}>Target Amount ($)</Text>
            <TextInput
              style={[sheetStyles.input, errors.targetAmount ? sheetStyles.inputError : null]}
              value={form.targetAmount}
              onChangeText={(v) => setField('targetAmount', v)}
              placeholder="e.g. 5000"
              placeholderTextColor={Colors.text.muted}
              keyboardType="decimal-pad"
              returnKeyType="done"
              accessibilityLabel="Target amount"
            />
            {errors.targetAmount ? (
              <Text style={sheetStyles.errorText}>{errors.targetAmount}</Text>
            ) : null}
          </View>

          {/* Target Date */}
          <DatePickerInput
            label="Target Date"
            value={form.targetDate}
            onChange={(v) => setField('targetDate', v)}
            error={errors.targetDate}
            accessibilityLabel="Target date"
          />

          {/* Icon */}
          <View style={sheetStyles.fieldGroup}>
            <Text style={sheetStyles.label}>
              Icon{' '}
              <Text style={sheetStyles.optionalLabel}>(optional, single emoji)</Text>
            </Text>
            <TextInput
              style={sheetStyles.input}
              value={form.icon}
              onChangeText={(v) => setField('icon', v)}
              placeholder="🎯"
              placeholderTextColor={Colors.text.muted}
              maxLength={2}
              returnKeyType="done"
              accessibilityLabel="Goal icon"
            />
          </View>
        </ScrollView>

        {/* Submit */}
        <View style={sheetStyles.footer}>
          <TouchableOpacity
            style={[sheetStyles.submitBtn, isSubmitting && sheetStyles.submitBtnDisabled]}
            onPress={handleSubmit}
            disabled={isSubmitting}
            activeOpacity={0.8}
            accessibilityRole="button"
            accessibilityLabel="Create savings goal"
          >
            {isSubmitting ? (
              <ActivityIndicator color="#FFFFFF" />
            ) : (
              <Text style={sheetStyles.submitBtnText}>Create Goal</Text>
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  )
}

// ─── AddFundsSheet ────────────────────────────────────────────────────────────

interface AddFundsSheetProps {
  visible: boolean
  goalId: string | null
  onClose: () => void
  onSubmit: (goalId: string, data: FundsFormData) => void
  isSubmitting: boolean
}

function AddFundsSheet({
  visible,
  goalId,
  onClose,
  onSubmit,
  isSubmitting,
}: AddFundsSheetProps) {
  const [amount, setAmount] = useState('')
  const [error, setError] = useState<string | undefined>()

  useEffect(() => {
    if (visible) {
      setAmount('')
      setError(undefined)
    }
  }, [visible])

  function handleSubmit() {
    const num = parseFloat(amount)
    if (!amount || isNaN(num) || num <= 0) {
      setError('Enter an amount greater than 0.')
      return
    }
    setError(undefined)
    if (goalId) onSubmit(goalId, { amount })
  }

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <KeyboardAvoidingView
        style={sheetStyles.root}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <View style={sheetStyles.header}>
          <Text style={sheetStyles.title}>Add Funds</Text>
          <TouchableOpacity
            style={sheetStyles.closeBtn}
            onPress={onClose}
            activeOpacity={0.7}
            accessibilityRole="button"
            accessibilityLabel="Close add funds form"
          >
            <X size={18} color={Colors.text.secondary} strokeWidth={2} />
          </TouchableOpacity>
        </View>

        <View style={sheetStyles.scrollContent}>
          <View style={sheetStyles.fieldGroup}>
            <Text style={sheetStyles.label}>Amount ($)</Text>
            <TextInput
              style={[sheetStyles.input, error ? sheetStyles.inputError : null]}
              value={amount}
              onChangeText={(v) => {
                setAmount(v)
                if (error) setError(undefined)
              }}
              placeholder="e.g. 200"
              placeholderTextColor={Colors.text.muted}
              keyboardType="decimal-pad"
              returnKeyType="done"
              autoFocus
              accessibilityLabel="Amount to add"
            />
            {error ? <Text style={sheetStyles.errorText}>{error}</Text> : null}
          </View>
        </View>

        <View style={sheetStyles.footer}>
          <TouchableOpacity
            style={[sheetStyles.submitBtn, isSubmitting && sheetStyles.submitBtnDisabled]}
            onPress={handleSubmit}
            disabled={isSubmitting}
            activeOpacity={0.8}
            accessibilityRole="button"
            accessibilityLabel="Add funds to goal"
          >
            {isSubmitting ? (
              <ActivityIndicator color="#FFFFFF" />
            ) : (
              <Text style={sheetStyles.submitBtnText}>Add Funds</Text>
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  )
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function SavingsScreen() {
  const { data, isLoading, isError, refetch } = useSavingsGoals()
  const createGoal = useCreateSavingsGoal()
  const deleteGoal = useDeleteSavingsGoal()
  const addFunds = useAddFunds()

  const [goalFormVisible, setGoalFormVisible] = useState(false)
  const [addFundsGoalId, setAddFundsGoalId] = useState<string | null>(null)

  const onRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  const isEmpty = !isLoading && !isError && (!data || data.length === 0)

  function handleCreateGoal(formData: GoalFormData) {
    createGoal.mutate(
      {
        name: formData.name.trim(),
        icon: formData.icon.trim() || '🎯',
        targetAmount: parseFloat(formData.targetAmount),
        targetDate: new Date(formData.targetDate),
      },
      { onSuccess: () => setGoalFormVisible(false) },
    )
  }

  function handleDeleteGoal(id: string) {
    Alert.alert(
      'Delete Goal',
      'Are you sure you want to delete this savings goal? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => deleteGoal.mutate(id),
        },
      ],
    )
  }

  function handleAddFundsSubmit(goalId: string, fundsData: FundsFormData) {
    addFunds.mutate(
      { id: goalId, req: { amount: parseFloat(fundsData.amount) } },
      { onSuccess: () => setAddFundsGoalId(null) },
    )
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Savings Goals</Text>
      </View>

      {/* ── Content ── */}
      {isError ? (
        <ErrorState onRetry={refetch} />
      ) : (
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={isLoading}
              onRefresh={onRefresh}
              tintColor={Colors.purple[500]}
              colors={[Colors.purple[500]]}
            />
          }
        >
          <View style={styles.section}>
            {isLoading ? (
              Array.from({ length: 3 }).map((_, i) => <GoalCardSkeleton key={i} />)
            ) : isEmpty ? (
              <EmptyState />
            ) : (
              data?.map((goal, idx) => (
                <GoalCard
                  key={goal.id}
                  goal={goal}
                  index={idx}
                  onAddFunds={(id) => setAddFundsGoalId(id)}
                  onDelete={handleDeleteGoal}
                />
              ))
            )}
          </View>

          <View style={styles.bottomSpacer} />
        </ScrollView>
      )}

      {/* ── FAB ── */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => setGoalFormVisible(true)}
        activeOpacity={0.85}
        accessibilityRole="button"
        accessibilityLabel="Create savings goal"
      >
        <Plus size={24} color="#FFFFFF" strokeWidth={2.5} />
      </TouchableOpacity>

      {/* ── Create Goal Sheet ── */}
      <SavingsGoalFormSheet
        visible={goalFormVisible}
        onClose={() => setGoalFormVisible(false)}
        onSubmit={handleCreateGoal}
        isSubmitting={createGoal.isPending}
      />

      {/* ── Add Funds Sheet ── */}
      <AddFundsSheet
        visible={addFundsGoalId !== null}
        goalId={addFundsGoalId}
        onClose={() => setAddFundsGoalId(null)}
        onSubmit={handleAddFundsSubmit}
        isSubmitting={addFunds.isPending}
      />
    </SafeAreaView>
  )
}

// ─── Shared sheet styles ───────────────────────────────────────────────────────

const sheetStyles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border.subtle,
  },
  title: {
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
    marginBottom: 20,
    paddingHorizontal: 20,
    paddingTop: 20,
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

// ─── Screen styles ────────────────────────────────────────────────────────────

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
    color: Colors.dark.text.primary,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  section: {
    paddingHorizontal: 20,
    gap: 10,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    paddingTop: 80,
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
    color: Colors.dark.text.primary,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 13,
    color: Colors.dark.text.muted,
    textAlign: 'center',
    lineHeight: 20,
  },
  retryButton: {
    marginTop: 6,
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: Colors.purple[600],
  },
  retryText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  bottomSpacer: {
    height: 100,
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
