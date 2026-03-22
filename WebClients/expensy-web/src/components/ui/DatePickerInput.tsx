import React, { useMemo, useState } from 'react'
import {
  Modal,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { CalendarDays, ChevronLeft, ChevronRight } from 'lucide-react-native'
import { format } from 'date-fns'
import { Colors } from '@/constants/colors'

// ─── Constants ────────────────────────────────────────────────────────────────

const WEEK_LABELS = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getTodayStr(): string {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function toDateStr(year: number, month: number, day: number): string {
  return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
}

function parseLocalDate(str: string): Date | null {
  if (!str) return null
  const parts = str.split('-').map(Number)
  if (parts.length !== 3 || parts.some(isNaN)) return null
  const date = new Date(parts[0], parts[1] - 1, parts[2])
  return isNaN(date.getTime()) ? null : date
}

function buildGrid(year: number, month: number): (number | null)[][] {
  const firstDay = new Date(year, month, 1).getDay()
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const cells: (number | null)[] = Array(firstDay).fill(null)
  for (let d = 1; d <= daysInMonth; d++) cells.push(d)
  while (cells.length % 7 !== 0) cells.push(null)
  const rows: (number | null)[][] = []
  for (let i = 0; i < cells.length; i += 7) rows.push(cells.slice(i, i + 7))
  return rows
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface DatePickerInputProps {
  label: string
  value: string                    // YYYY-MM-DD, or '' for no date
  onChange: (date: string) => void
  error?: string
  optional?: boolean               // shows "Clear" button and "(optional)" label hint
  placeholder?: string
  accessibilityLabel?: string
}

// ─── Component ────────────────────────────────────────────────────────────────

export function DatePickerInput({
  label,
  value,
  onChange,
  error,
  optional = false,
  placeholder = 'Select a date',
  accessibilityLabel,
}: DatePickerInputProps) {
  const [open, setOpen] = useState(false)

  const todayStr = getTodayStr()
  const parsedValue = parseLocalDate(value)

  const [tempYear, setTempYear] = useState(new Date().getFullYear())
  const [tempMonth, setTempMonth] = useState(new Date().getMonth())
  const [tempSelected, setTempSelected] = useState<string>(value || todayStr)

  function openPicker() {
    const base = parsedValue ?? new Date()
    setTempYear(base.getFullYear())
    setTempMonth(base.getMonth())
    setTempSelected(value || todayStr)
    setOpen(true)
  }

  function prevMonth() {
    if (tempMonth === 0) {
      setTempMonth(11)
      setTempYear((y) => y - 1)
    } else {
      setTempMonth((m) => m - 1)
    }
  }

  function nextMonth() {
    if (tempMonth === 11) {
      setTempMonth(0)
      setTempYear((y) => y + 1)
    } else {
      setTempMonth((m) => m + 1)
    }
  }

  function handleConfirm() {
    onChange(tempSelected)
    setOpen(false)
  }

  function handleClear() {
    onChange('')
    setOpen(false)
  }

  const grid = useMemo(() => buildGrid(tempYear, tempMonth), [tempYear, tempMonth])

  const displayText = parsedValue ? format(parsedValue, 'MMM d, yyyy') : null

  return (
    <View>
      {/* ── Label ── */}
      <View style={styles.labelRow}>
        <Text style={styles.label}>{label}</Text>
        {optional && <Text style={styles.optionalHint}> (optional)</Text>}
      </View>

      {/* ── Trigger field ── */}
      <TouchableOpacity
        style={[styles.field, error ? styles.fieldError : null]}
        onPress={openPicker}
        activeOpacity={0.7}
        accessibilityRole="button"
        accessibilityLabel={accessibilityLabel ?? label}
      >
        <Text style={[styles.fieldText, !displayText && styles.fieldPlaceholder]}>
          {displayText ?? placeholder}
        </Text>
        <CalendarDays size={17} color={Colors.text.muted} strokeWidth={2} />
      </TouchableOpacity>

      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      {/* ── Calendar modal ── */}
      <Modal
        visible={open}
        transparent
        animationType="fade"
        onRequestClose={() => setOpen(false)}
        statusBarTranslucent
      >
        {/* Backdrop tap to dismiss */}
        <TouchableOpacity
          style={styles.backdrop}
          activeOpacity={1}
          onPress={() => setOpen(false)}
        >
          {/* Card — inner TouchableOpacity swallows taps so backdrop doesn't fire */}
          <TouchableOpacity
            style={styles.card}
            activeOpacity={1}
            onPress={() => undefined}
          >
            {/* Month navigation */}
            <View style={styles.navRow}>
              <TouchableOpacity style={styles.navBtn} onPress={prevMonth} activeOpacity={0.7}>
                <ChevronLeft size={18} color={Colors.text.secondary} strokeWidth={2.5} />
              </TouchableOpacity>
              <Text style={styles.monthLabel}>
                {MONTH_NAMES[tempMonth]} {tempYear}
              </Text>
              <TouchableOpacity style={styles.navBtn} onPress={nextMonth} activeOpacity={0.7}>
                <ChevronRight size={18} color={Colors.text.secondary} strokeWidth={2.5} />
              </TouchableOpacity>
            </View>

            {/* Week day headers */}
            <View style={styles.gridRow}>
              {WEEK_LABELS.map((d) => (
                <View key={d} style={styles.dayCell}>
                  <Text style={styles.weekLabel}>{d}</Text>
                </View>
              ))}
            </View>

            {/* Day grid */}
            {grid.map((row, ri) => (
              <View key={ri} style={styles.gridRow}>
                {row.map((day, ci) => {
                  if (!day) return <View key={ci} style={styles.dayCell} />
                  const ds = toDateStr(tempYear, tempMonth, day)
                  const isSelected = tempSelected === ds
                  const isToday = todayStr === ds
                  return (
                    <TouchableOpacity
                      key={ci}
                      style={[
                        styles.dayCell,
                        isSelected && styles.daySelected,
                        isToday && !isSelected && styles.dayToday,
                      ]}
                      onPress={() => setTempSelected(ds)}
                      activeOpacity={0.65}
                    >
                      <Text
                        style={[
                          styles.dayText,
                          isSelected && styles.dayTextSelected,
                          isToday && !isSelected && styles.dayTextToday,
                        ]}
                      >
                        {day}
                      </Text>
                    </TouchableOpacity>
                  )
                })}
              </View>
            ))}

            {/* Footer */}
            <View style={[styles.calFooter, optional && styles.calFooterWithClear]}>
              {optional && (
                <TouchableOpacity style={styles.clearBtn} onPress={handleClear} activeOpacity={0.7}>
                  <Text style={styles.clearBtnText}>Clear</Text>
                </TouchableOpacity>
              )}
              <TouchableOpacity
                style={[styles.confirmBtn, optional && styles.confirmBtnFlex]}
                onPress={handleConfirm}
                activeOpacity={0.8}
              >
                <Text style={styles.confirmBtnText}>Confirm</Text>
              </TouchableOpacity>
            </View>
          </TouchableOpacity>
        </TouchableOpacity>
      </Modal>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  // ── Field trigger ────────────────────────────────────────────────────────

  labelRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: 8,
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.text.secondary,
    letterSpacing: 0.3,
  },
  optionalHint: {
    fontSize: 12,
    fontWeight: '400',
    color: Colors.text.muted,
  },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    minHeight: 46,
  },
  fieldError: {
    borderColor: Colors.danger,
  },
  fieldText: {
    fontSize: 15,
    color: Colors.text.primary,
    flex: 1,
  },
  fieldPlaceholder: {
    color: Colors.text.muted,
  },
  errorText: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.danger,
  },

  // ── Modal ────────────────────────────────────────────────────────────────

  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.72)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  card: {
    width: 320,
    backgroundColor: Colors.bg.elevated,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: Colors.border.strong,
    paddingHorizontal: 16,
    paddingTop: 20,
    paddingBottom: 16,
  },

  // ── Month navigation ─────────────────────────────────────────────────────

  navRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 14,
  },
  navBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.bg.overlay,
    alignItems: 'center',
    justifyContent: 'center',
  },
  monthLabel: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.text.primary,
    letterSpacing: 0.1,
  },

  // ── Grid ─────────────────────────────────────────────────────────────────

  gridRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 4,
  },
  weekLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: Colors.text.muted,
    letterSpacing: 0.6,
    textTransform: 'uppercase',
  },

  // ── Day cells ────────────────────────────────────────────────────────────

  dayCell: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  daySelected: {
    backgroundColor: Colors.purple[600],
  },
  dayToday: {
    borderWidth: 1.5,
    borderColor: Colors.purple[500],
  },
  dayText: {
    fontSize: 14,
    fontWeight: '500',
    color: Colors.text.primary,
  },
  dayTextSelected: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  dayTextToday: {
    color: Colors.purple[400],
    fontWeight: '600',
  },

  // ── Footer ───────────────────────────────────────────────────────────────

  calFooter: {
    marginTop: 14,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: Colors.border.subtle,
  },
  calFooterWithClear: {
    flexDirection: 'row',
    gap: 8,
  },
  clearBtn: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: Colors.bg.overlay,
    borderWidth: 1,
    borderColor: Colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
  },
  clearBtnText: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text.secondary,
  },
  confirmBtn: {
    paddingVertical: 11,
    borderRadius: 10,
    backgroundColor: Colors.purple[600],
    alignItems: 'center',
  },
  confirmBtnFlex: {
    flex: 1,
  },
  confirmBtnText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#FFFFFF',
    letterSpacing: 0.1,
  },
})
