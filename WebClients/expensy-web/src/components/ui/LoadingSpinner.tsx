import React from 'react'
import { ActivityIndicator, StyleSheet, View } from 'react-native'
import { Colors } from '@/constants/colors'

export function LoadingSpinner() {
  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" color={Colors.primary[500]} />
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.surface[50],
  },
})
