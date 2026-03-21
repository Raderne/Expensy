import React, { useCallback, useEffect, useState } from 'react'
import {
  Alert,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import {
  Bell,
  ChevronRight,
  DollarSign,
  Globe,
  LogOut,
  Moon,
  Shield,
  Target,
  User,
} from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { useAuthStore } from '@/store/auth.store'
import { AvatarCircle } from '@/components/profile/AvatarCircle'
import { SettingsGroup } from '@/components/settings/SettingsGroup'
import { SettingsRow } from '@/components/settings/SettingsRow'
import {
  useProfile,
  useUpdateNotificationPreferences,
  type NotificationPreferences,
} from '@/hooks/useProfile'

// ─── Profile Header ───────────────────────────────────────────────────────────

interface ProfileHeaderProps {
  fullName: string
  email: string
  avatarUrl?: string | null
  onEditPress: () => void
}

function ProfileHeader({ fullName, email, avatarUrl, onEditPress }: ProfileHeaderProps) {
  return (
    <View style={styles.profileHeader}>
      <AvatarCircle name={fullName} avatarUrl={avatarUrl} size="lg" />
      <View style={styles.profileInfo}>
        <Text style={styles.profileName} numberOfLines={1}>
          {fullName}
        </Text>
        <Text style={styles.profileEmail} numberOfLines={1}>
          {email}
        </Text>
      </View>
      <Pressable
        onPress={onEditPress}
        accessibilityRole="button"
        accessibilityLabel="Edit profile"
        style={({ pressed }) => [styles.editLink, pressed && styles.editLinkPressed]}
      >
        <Text style={styles.editLinkText}>Edit Profile</Text>
      </Pressable>
    </View>
  )
}

function ProfileHeaderSkeleton() {
  return (
    <View style={styles.profileHeader}>
      <View style={styles.avatarSkeleton} />
      <View style={styles.profileInfo}>
        <View style={styles.skeletonNameLine} />
        <View style={styles.skeletonEmailLine} />
      </View>
    </View>
  )
}

// ─── Logout Button ────────────────────────────────────────────────────────────

interface LogoutButtonProps {
  onPress: () => void
}

function LogoutButton({ onPress }: LogoutButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel="Log out of Expensy"
      style={({ pressed }) => [styles.logoutButton, pressed && styles.logoutButtonPressed]}
    >
      <LogOut size={17} color={Colors.danger} strokeWidth={2} />
      <Text style={styles.logoutText}>Log Out</Text>
    </Pressable>
  )
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function SettingsScreen() {
  const { user, clearAuth } = useAuthStore()
  const { data: profile, isLoading, refetch } = useProfile()
  const { mutate: updateNotifPrefs } = useUpdateNotificationPreferences()

  // ── Local toggle state — seeded from profile data ──
  const [darkTheme, setDarkTheme] = useState(true)
  const [budgetAlerts, setBudgetAlerts] = useState(true)
  const [renewalReminders, setRenewalReminders] = useState(true)
  const [milestoneAlerts, setMilestoneAlerts] = useState(false)
  const [notifSeedDone, setNotifSeedDone] = useState(false)

  useEffect(() => {
    if (profile && !notifSeedDone) {
      const prefs = profile.notificationPreferences
      setBudgetAlerts(prefs.budgetAlerts)
      setRenewalReminders(prefs.renewalReminders)
      setMilestoneAlerts(prefs.milestoneAlerts)
      setNotifSeedDone(true)
    }
  }, [profile, notifSeedDone])

  // ── Notification preference helpers ──

  function handleNotifChange(key: keyof NotificationPreferences, value: boolean) {
    const next: NotificationPreferences = {
      budgetAlerts,
      renewalReminders,
      milestoneAlerts,
      [key]: value,
    }
    if (key === 'budgetAlerts') setBudgetAlerts(value)
    if (key === 'renewalReminders') setRenewalReminders(value)
    if (key === 'milestoneAlerts') setMilestoneAlerts(value)

    // TODO: API — replace with profileClient.updateNotificationPreferences(next)
    updateNotifPrefs(next)
  }

  // ── Logout ──

  const handleLogout = useCallback(() => {
    Alert.alert(
      'Log Out',
      'Are you sure you want to log out of Expensy?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Log Out',
          style: 'destructive',
          onPress: () => clearAuth(),
        },
      ],
      { cancelable: true },
    )
  }, [clearAuth])

  // ── Edit profile ──

  function handleEditProfile() {
    // TODO: navigate to profile edit screen once it is implemented
    // router.push('/(app)/edit-profile')
  }

  // ── Currency picker ──

  function handleCurrencyPress() {
    // TODO: API — show currency picker using data from useCurrencies()
    // For now, show an informational alert
    Alert.alert(
      'Currency',
      'Currency selection will be available once the settings API is connected.',
      [{ text: 'OK' }],
    )
  }

  const onRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  const displayName = profile?.fullName ?? user?.email ?? 'User'
  const displayEmail = profile?.email ?? user?.email ?? ''
  const currencyCode = profile?.currencyCode ?? 'USD'

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Settings</Text>
      </View>

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
        {/* ── Profile header ── */}
        {isLoading ? (
          <ProfileHeaderSkeleton />
        ) : (
          <ProfileHeader
            fullName={displayName}
            email={displayEmail}
            avatarUrl={profile?.avatar}
            onEditPress={handleEditProfile}
          />
        )}

        {/* ── App Settings ── */}
        <SettingsGroup title="App Settings">
          <SettingsRow
            label="Currency"
            description={`Currently set to ${currencyCode}`}
            icon={<DollarSign size={18} color={Colors.purple[400]} strokeWidth={2} />}
            rightElement={
              <Text style={styles.currencyBadge}>{currencyCode}</Text>
            }
            onPress={handleCurrencyPress}
          />
          <SettingsRow
            label="Dark Theme"
            description="App appearance — light/dark mode"
            icon={<Moon size={18} color={Colors.purple[400]} strokeWidth={2} />}
            rightElement={
              <Switch
                value={darkTheme}
                onValueChange={setDarkTheme}
                trackColor={{ false: Colors.border.default, true: Colors.purple[600] }}
                thumbColor={darkTheme ? Colors.purple[400] : Colors.text.muted}
                accessibilityLabel="Toggle dark theme"
              />
            }
          />
        </SettingsGroup>

        {/* ── Notifications ── */}
        <SettingsGroup title="Notifications">
          <SettingsRow
            label="Budget Alerts"
            description="Get notified when you approach budget limits"
            icon={<Bell size={18} color={Colors.purple[400]} strokeWidth={2} />}
            rightElement={
              <Switch
                value={budgetAlerts}
                onValueChange={(v) => handleNotifChange('budgetAlerts', v)}
                trackColor={{ false: Colors.border.default, true: Colors.purple[600] }}
                thumbColor={budgetAlerts ? Colors.purple[400] : Colors.text.muted}
                accessibilityLabel="Toggle budget alerts"
              />
            }
          />
          <SettingsRow
            label="Renewal Reminders"
            description="Reminders before subscriptions renew"
            icon={<Globe size={18} color={Colors.purple[400]} strokeWidth={2} />}
            rightElement={
              <Switch
                value={renewalReminders}
                onValueChange={(v) => handleNotifChange('renewalReminders', v)}
                trackColor={{ false: Colors.border.default, true: Colors.purple[600] }}
                thumbColor={renewalReminders ? Colors.purple[400] : Colors.text.muted}
                accessibilityLabel="Toggle renewal reminders"
              />
            }
          />
          <SettingsRow
            label="Milestone Alerts"
            description="Celebrate savings goal milestones"
            icon={<Target size={18} color={Colors.purple[400]} strokeWidth={2} />}
            rightElement={
              <Switch
                value={milestoneAlerts}
                onValueChange={(v) => handleNotifChange('milestoneAlerts', v)}
                trackColor={{ false: Colors.border.default, true: Colors.purple[600] }}
                thumbColor={milestoneAlerts ? Colors.purple[400] : Colors.text.muted}
                accessibilityLabel="Toggle milestone alerts"
              />
            }
          />
        </SettingsGroup>

        {/* ── Account ── */}
        <SettingsGroup title="Account">
          <SettingsRow
            label="Manage Profile"
            description="Update your name, email, and avatar"
            icon={<User size={18} color={Colors.purple[400]} strokeWidth={2} />}
            onPress={handleEditProfile}
          />
          <SettingsRow
            label="Privacy & Security"
            description="Data and account security settings"
            icon={<Shield size={18} color={Colors.purple[400]} strokeWidth={2} />}
            onPress={() => {
              // TODO: navigate to privacy screen
            }}
          />
          <SettingsRow
            label="Version"
            rightElement={<Text style={styles.versionText}>v1.0.0</Text>}
            disabled
          />
        </SettingsGroup>

        {/* ── Logout ── */}
        <LogoutButton onPress={handleLogout} />

        <View style={styles.bottomSpacer} />
      </ScrollView>
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
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 16,
    gap: 24,
    paddingBottom: 20,
  },

  // ── Profile header ──
  profileHeader: {
    alignItems: 'center',
    gap: 12,
    paddingTop: 8,
    paddingBottom: 4,
  },
  profileInfo: {
    alignItems: 'center',
    gap: 4,
  },
  profileName: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.text.primary,
    textAlign: 'center',
  },
  profileEmail: {
    fontSize: 13,
    color: Colors.text.secondary,
    textAlign: 'center',
  },
  editLink: {
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: Colors.border.default,
  },
  editLinkPressed: {
    opacity: 0.65,
  },
  editLinkText: {
    fontSize: 13,
    fontWeight: '500',
    color: Colors.purple[400],
  },

  // ── Skeletons ──
  avatarSkeleton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: Colors.bg.elevated,
  },
  skeletonNameLine: {
    width: 140,
    height: 18,
    borderRadius: 6,
    backgroundColor: Colors.bg.elevated,
  },
  skeletonEmailLine: {
    width: 180,
    height: 14,
    borderRadius: 6,
    backgroundColor: Colors.bg.elevated,
    marginTop: 4,
  },

  // ── Row decorations ──
  currencyBadge: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.text.secondary,
    marginRight: 4,
  },
  versionText: {
    fontSize: 13,
    color: Colors.text.muted,
  },

  // ── Logout ──
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 15,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(239, 68, 68, 0.3)',
    backgroundColor: 'rgba(239, 68, 68, 0.06)',
  },
  logoutButtonPressed: {
    opacity: 0.7,
    backgroundColor: 'rgba(239, 68, 68, 0.12)',
  },
  logoutText: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.danger,
  },

  bottomSpacer: {
    height: 16,
  },
})
