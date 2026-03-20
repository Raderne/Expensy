import React, { useState } from 'react'
import {
  ActivityIndicator,
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native'
import { Colors } from '@/constants/colors'
import { useCreateWallet } from '@/hooks/useWallets'

const ICONS = ['💳', '🏦', '💰', '🪙', '💵', '🏧', '💼', '🎯', '🛍️', '✈️']

interface CreateWalletModalProps {
  visible: boolean
  onClose: () => void
}

export function CreateWalletModal({ visible, onClose }: CreateWalletModalProps) {
  const [name, setName] = useState('')
  const [balance, setBalance] = useState('')
  const [selectedIcon, setSelectedIcon] = useState(ICONS[0])
  const [error, setError] = useState<string | null>(null)

  const { mutate: createWallet, isPending } = useCreateWallet()

  const handleCreate = () => {
    setError(null)
    const trimmedName = name.trim()
    if (!trimmedName) {
      setError('Wallet name is required.')
      return
    }
    const parsedBalance = parseFloat(balance) || 0
    if (parsedBalance < 0) {
      setError('Balance cannot be negative.')
      return
    }

    createWallet(
      { name: trimmedName, initialBalance: parsedBalance, icon: selectedIcon },
      {
        onSuccess: () => {
          setName('')
          setBalance('')
          setSelectedIcon(ICONS[0])
          setError(null)
          onClose()
        },
        onError: () => setError('Failed to create wallet. Please try again.'),
      },
    )
  }

  const handleClose = () => {
    setName('')
    setBalance('')
    setSelectedIcon(ICONS[0])
    setError(null)
    onClose()
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
          {/* Handle */}
          <View style={styles.handle} />

          <Text style={styles.title}>New Wallet</Text>

          {error ? (
            <View style={styles.errorBox}>
              <Text style={styles.errorText}>{error}</Text>
            </View>
          ) : null}

          {/* Name */}
          <Text style={styles.label}>Name</Text>
          <TextInput
            style={styles.input}
            placeholder="e.g. Main Account"
            placeholderTextColor={Colors.text.muted}
            value={name}
            onChangeText={setName}
            autoCapitalize="words"
            returnKeyType="next"
          />

          {/* Initial Balance */}
          <Text style={styles.label}>Initial Balance</Text>
          <TextInput
            style={styles.input}
            placeholder="0.00"
            placeholderTextColor={Colors.text.muted}
            value={balance}
            onChangeText={setBalance}
            keyboardType="decimal-pad"
            returnKeyType="done"
          />

          {/* Icon picker */}
          <Text style={styles.label}>Icon</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.iconRow}
          >
            {ICONS.map((icon) => (
              <TouchableOpacity
                key={icon}
                style={[
                  styles.iconOption,
                  selectedIcon === icon && styles.iconOptionActive,
                ]}
                onPress={() => setSelectedIcon(icon)}
                accessibilityRole="button"
                accessibilityState={{ selected: selectedIcon === icon }}
              >
                <Text style={styles.iconEmoji}>{icon}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {/* Actions */}
          <TouchableOpacity
            style={[styles.createBtn, isPending && styles.createBtnDisabled]}
            onPress={handleCreate}
            disabled={isPending}
            activeOpacity={0.8}
          >
            {isPending ? (
              <ActivityIndicator color="#fff" size="small" />
            ) : (
              <Text style={styles.createBtnText}>Create Wallet</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.cancelBtn}
            onPress={handleClose}
            disabled={isPending}
          >
            <Text style={styles.cancelBtnText}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  )
}

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
    paddingBottom: 36,
    paddingTop: 12,
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
    color: Colors.text.primary,
    marginBottom: 16,
  },
  errorBox: {
    backgroundColor: 'rgba(239,68,68,0.12)',
    borderWidth: 1,
    borderColor: Colors.danger,
    borderRadius: 10,
    padding: 10,
    marginBottom: 12,
  },
  errorText: {
    color: Colors.danger,
    fontSize: 13,
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.text.secondary,
    marginBottom: 6,
    marginTop: 12,
  },
  input: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: Colors.border.default,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    color: Colors.text.primary,
  },
  iconRow: {
    gap: 10,
    paddingVertical: 4,
  },
  iconOption: {
    width: 48,
    height: 48,
    borderRadius: 12,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 2,
    borderColor: 'transparent',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconOptionActive: {
    borderColor: Colors.purple[500],
    backgroundColor: Colors.bg.overlay,
  },
  iconEmoji: {
    fontSize: 24,
  },
  createBtn: {
    backgroundColor: Colors.purple[600],
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 24,
  },
  createBtnDisabled: {
    opacity: 0.6,
  },
  createBtnText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#fff',
  },
  cancelBtn: {
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 8,
  },
  cancelBtnText: {
    fontSize: 15,
    fontWeight: '500',
    color: Colors.text.secondary,
  },
})
