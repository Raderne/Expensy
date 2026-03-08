import React, { useState, useCallback } from 'react'
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { router } from 'expo-router'
import { X } from 'lucide-react-native'
import { format } from 'date-fns'
import { Colors } from '@/constants/colors'
import { useWallets } from '@/hooks/useWallets'
import { useCategories } from '@/hooks/useCategories'
import { useCreateTransaction } from '@/hooks/useTransactions'
import { useNumPad } from '@/hooks/useNumPad'
import { WalletDto } from '@/api/wallets.api'
import { CategoryDto } from '@/api/categories.api'
import { NumPad } from '@/components/expense/NumPad'
import { WalletSelector } from '@/components/expense/WalletSelector'
import { CategoryChipSelector } from '@/components/expense/CategoryChipSelector'
import { AutoDateToggle } from '@/components/expense/AutoDateToggle'

// ─── Type toggle ─────────────────────────────────────────────────────────────

type TxType = 'expense' | 'income'

// ─── Screen ──────────────────────────────────────────────────────────────────

export default function AddExpenseScreen() {
  const {
    displayAmount,
    numericAmount,
    amount,
    handleDigit,
    handleDot,
    handleBackspace,
  } = useNumPad()

  const [txType, setTxType] = useState<TxType>('expense')
  const [selectedWallet, setSelectedWallet] = useState<WalletDto | null>(null)
  const [selectedCategory, setSelectedCategory] = useState<CategoryDto | null>(null)
  const [autoDate, setAutoDate] = useState(true)
  const [selectedDate] = useState<Date>(new Date())

  const { data: wallets = [], isLoading: walletsLoading } = useWallets()
  const { data: categories = [], isLoading: categoriesLoading } = useCategories()
  const { mutateAsync: createTransaction, isPending: isSaving } = useCreateTransaction()

  // Auto-select first wallet when data loads
  const resolvedWallet = selectedWallet ?? wallets[0] ?? null

  const handleSelectWallet = useCallback((wallet: WalletDto) => {
    setSelectedWallet(wallet)
  }, [])

  const handleSelectCategory = useCallback((category: CategoryDto) => {
    setSelectedCategory(category)
  }, [])

  function handleClose() {
    if (amount !== '') {
      Alert.alert(
        'Save as Draft?',
        'You have an unsaved amount. Would you like to save it as a draft?',
        [
          { text: 'Discard', style: 'destructive', onPress: () => router.back() },
          { text: 'Keep editing', style: 'cancel' },
          {
            text: 'Save Draft',
            onPress: () => {
              // Draft save: future feature
              router.back()
            },
          },
        ],
      )
    } else {
      router.back()
    }
  }

  async function handleSave() {
    if (numericAmount <= 0) return
    if (!resolvedWallet) {
      Alert.alert('No wallet selected', 'Please select a wallet to continue.')
      return
    }
    if (!selectedCategory) {
      Alert.alert('No category selected', 'Please select a category to continue.')
      return
    }

    try {
      await createTransaction({
        walletId: resolvedWallet.id,
        categoryId: selectedCategory.id,
        amount: numericAmount,
        type: txType,
        description: selectedCategory.name,
        date: autoDate
          ? new Date().toISOString()
          : selectedDate.toISOString(),
        paymentMethod: 'Card',
      })
      router.back()
    } catch {
      Alert.alert('Error', 'Could not save the transaction. Please try again.')
    }
  }

  const canSave = numericAmount > 0 && !isSaving

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        {/* ── Header ── */}
        <View style={styles.header}>
          <TouchableOpacity
            onPress={handleClose}
            style={styles.headerButton}
            accessibilityRole="button"
            accessibilityLabel="Close"
          >
            <X size={22} color={Colors.dark.text.primary} strokeWidth={2} />
          </TouchableOpacity>

          <Text style={styles.headerTitle}>Add New Expense</Text>

          <TouchableOpacity
            style={styles.headerButton}
            accessibilityRole="button"
            accessibilityLabel="Drafts"
          >
            <Text style={styles.draftsLabel}>Drafts</Text>
          </TouchableOpacity>
        </View>

        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        >
          {/* ── Type toggle ── */}
          <View style={styles.typeToggle}>
            {(['expense', 'income'] as TxType[]).map((type) => (
              <TouchableOpacity
                key={type}
                style={[
                  styles.typeButton,
                  txType === type && styles.typeButtonActive,
                ]}
                onPress={() => setTxType(type)}
                activeOpacity={0.75}
              >
                <Text
                  style={[
                    styles.typeButtonLabel,
                    txType === type && styles.typeButtonLabelActive,
                  ]}
                >
                  {type.charAt(0).toUpperCase() + type.slice(1)}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          {/* ── Amount display ── */}
          <View style={styles.amountSection}>
            <Text style={styles.amountLabel}>TOTAL AMOUNT</Text>
            <Text style={styles.amountDisplay}>
              ${displayAmount}
            </Text>
          </View>

          {/* ── Wallet selector ── */}
          <View style={styles.formSection}>
            <WalletSelector
              wallets={wallets}
              selectedWalletId={resolvedWallet?.id ?? null}
              onSelect={handleSelectWallet}
              loading={walletsLoading}
            />
          </View>

          {/* ── Category chips ── */}
          <View style={styles.formSection}>
            <Text style={styles.fieldLabel}>Category</Text>
            <CategoryChipSelector
              categories={categories}
              selectedCategoryId={selectedCategory?.id ?? null}
              onSelect={handleSelectCategory}
              loading={categoriesLoading}
            />
          </View>

          {/* ── Date toggle ── */}
          <View style={styles.formSection}>
            <AutoDateToggle
              autoDate={autoDate}
              onToggle={setAutoDate}
              selectedDate={selectedDate}
            />
          </View>

          {/* ── NumPad ── */}
          <View style={styles.numPadSection}>
            <NumPad
              onDigit={handleDigit}
              onDot={handleDot}
              onBackspace={handleBackspace}
            />
          </View>

          {/* ── Save button ── */}
          <TouchableOpacity
            style={[styles.saveButton, !canSave && styles.saveButtonDisabled]}
            onPress={handleSave}
            disabled={!canSave}
            activeOpacity={0.8}
            accessibilityRole="button"
            accessibilityLabel="Save expense"
            accessibilityState={{ disabled: !canSave }}
          >
            <Text style={styles.saveButtonLabel}>
              {isSaving ? 'Saving…' : `Save ${txType.charAt(0).toUpperCase() + txType.slice(1)}`}
            </Text>
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  flex: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: Colors.dark.border.subtle,
  },
  headerButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.bg.elevated,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  draftsLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.purple[500],
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingBottom: 32,
    gap: 16,
  },
  typeToggle: {
    flexDirection: 'row',
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    padding: 4,
    marginTop: 8,
    borderWidth: 1,
    borderColor: Colors.dark.border.subtle,
  },
  typeButton: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 11,
    alignItems: 'center',
  },
  typeButtonActive: {
    backgroundColor: Colors.purple[600],
  },
  typeButtonLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.dark.text.muted,
  },
  typeButtonLabelActive: {
    color: '#FFFFFF',
  },
  amountSection: {
    alignItems: 'center',
    paddingVertical: 20,
    gap: 6,
  },
  amountLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: Colors.dark.text.muted,
    letterSpacing: 1.5,
  },
  amountDisplay: {
    fontSize: 52,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    letterSpacing: -1,
    minWidth: 160,
    textAlign: 'center',
  },
  formSection: {
    gap: 6,
  },
  fieldLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: Colors.dark.text.muted,
    letterSpacing: 0.5,
    paddingLeft: 2,
  },
  numPadSection: {
    marginTop: 4,
  },
  saveButton: {
    height: 54,
    borderRadius: 16,
    backgroundColor: Colors.purple[600],
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
    shadowColor: Colors.purple[500],
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 10,
    elevation: 6,
  },
  saveButtonDisabled: {
    backgroundColor: Colors.bg.elevated,
    shadowOpacity: 0,
    elevation: 0,
  },
  saveButtonLabel: {
    fontSize: 16,
    fontWeight: '700',
    color: '#FFFFFF',
  },
})
