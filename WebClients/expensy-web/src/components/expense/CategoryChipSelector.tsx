import React from 'react'
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { Colors } from '@/constants/colors'
import { CategoryDto } from '@/api/categories.api'

// Fallback categories when API data is unavailable
const FALLBACK_CATEGORIES: CategoryDto[] = [
  { id: 'shopping', name: 'Shopping', icon: '🛍️', color: '#B04EFF', isSystem: true },
  { id: 'dining', name: 'Dining', icon: '🍔', color: '#F97316', isSystem: true },
  { id: 'groceries', name: 'Groceries', icon: '🛒', color: '#22C55E', isSystem: true },
  { id: 'transport', name: 'Transport', icon: '🚌', color: '#3B82F6', isSystem: true },
  { id: 'health', name: 'Health', icon: '💊', color: '#EF4444', isSystem: true },
  { id: 'entertainment', name: 'Entertainment', icon: '🎬', color: '#F59E0B', isSystem: true },
]

interface CategoryChipSelectorProps {
  categories?: CategoryDto[]
  selectedCategoryId: string | null
  onSelect: (category: CategoryDto) => void
  loading?: boolean
}

export function CategoryChipSelector({
  categories,
  selectedCategoryId,
  onSelect,
  loading = false,
}: CategoryChipSelectorProps) {
  const items = categories && categories.length > 0 ? categories : FALLBACK_CATEGORIES

  if (loading) {
    return (
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.scroll}>
        {[0, 1, 2, 3].map((i) => (
          <View key={i} style={[styles.chip, styles.chipSkeleton]} />
        ))}
      </ScrollView>
    )
  }

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      style={styles.scroll}
      contentContainerStyle={styles.content}
    >
      {items.map((cat) => {
        const isSelected = cat.id === selectedCategoryId
        return (
          <TouchableOpacity
            key={cat.id}
            style={[
              styles.chip,
              isSelected && styles.chipSelected,
              !isSelected && { borderColor: Colors.dark.border.default },
            ]}
            onPress={() => onSelect(cat)}
            activeOpacity={0.7}
            accessibilityRole="button"
            accessibilityState={{ selected: isSelected }}
          >
            <Text style={styles.chipIcon}>{cat.icon}</Text>
            <Text
              style={[
                styles.chipLabel,
                isSelected ? styles.chipLabelSelected : styles.chipLabelDefault,
              ]}
            >
              {cat.name}
            </Text>
          </TouchableOpacity>
        )
      })}
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  scroll: {
    flexGrow: 0,
  },
  content: {
    gap: 8,
    paddingHorizontal: 2,
    paddingVertical: 4,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 14,
    paddingVertical: 9,
    borderRadius: 100,
    borderWidth: 1,
    borderColor: 'transparent',
    backgroundColor: Colors.bg.elevated,
  },
  chipSelected: {
    backgroundColor: 'rgba(176,78,255,0.18)',
    borderColor: Colors.purple[500],
  },
  chipSkeleton: {
    width: 96,
    height: 38,
    backgroundColor: Colors.bg.elevated,
    opacity: 0.5,
  },
  chipIcon: {
    fontSize: 15,
  },
  chipLabel: {
    fontSize: 13,
    fontWeight: '600',
  },
  chipLabelDefault: {
    color: Colors.dark.text.secondary,
  },
  chipLabelSelected: {
    color: Colors.purple[400],
  },
})
