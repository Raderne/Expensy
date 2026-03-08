import React from 'react'
import { StyleSheet, Switch, Text, View } from 'react-native'
import { Calendar } from 'lucide-react-native'
import { format } from 'date-fns'
import { Colors } from '@/constants/colors'

interface AutoDateToggleProps {
  autoDate: boolean
  onToggle: (value: boolean) => void
  selectedDate?: Date
}

export function AutoDateToggle({ autoDate, onToggle, selectedDate }: AutoDateToggleProps) {
  const displayDate = selectedDate
    ? format(selectedDate, 'MMM d, yyyy')
    : format(new Date(), 'MMM d, yyyy')

  return (
    <View style={styles.container}>
      <View style={styles.iconWrap}>
        <Calendar size={16} color={Colors.purple[500]} strokeWidth={2} />
      </View>
      <View style={styles.textGroup}>
        <Text style={styles.label}>
          {autoDate ? 'Automatic Date' : displayDate}
        </Text>
        {autoDate && (
          <Text style={styles.sub}>{displayDate}</Text>
        )}
      </View>
      <Switch
        value={autoDate}
        onValueChange={onToggle}
        trackColor={{
          false: Colors.dark.border.default,
          true: Colors.purple[600],
        }}
        thumbColor={autoDate ? Colors.purple[300] : Colors.dark.text.muted}
        ios_backgroundColor={Colors.dark.border.default}
        accessibilityLabel="Toggle automatic date"
      />
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: Colors.dark.border.default,
    gap: 12,
  },
  iconWrap: {
    width: 32,
    height: 32,
    borderRadius: 10,
    backgroundColor: 'rgba(176,78,255,0.12)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  textGroup: {
    flex: 1,
    gap: 2,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.dark.text.primary,
  },
  sub: {
    fontSize: 12,
    color: Colors.dark.text.muted,
  },
})
