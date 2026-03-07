import React from 'react'
import { Redirect, Tabs } from 'expo-router'
import { LayoutDashboard, Wallet, ArrowLeftRight, PieChart, PiggyBank } from 'lucide-react-native'
import { useAuthStore } from '@/store/auth.store'
import { Colors } from '@/constants/colors'

export default function AppLayout() {
  const { isAuthenticated, isInitialized } = useAuthStore()

  if (!isAuthenticated && isInitialized) {
    return <Redirect href="/(auth)/login" />
  }

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Colors.primary[500],
        tabBarInactiveTintColor: Colors.text.secondary,
        tabBarStyle: {
          backgroundColor: Colors.surface[0],
          borderTopColor: Colors.surface[200],
          borderTopWidth: 1,
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '500',
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ color, size }) => (
            <LayoutDashboard size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="wallets"
        options={{
          title: 'Wallets',
          tabBarIcon: ({ color, size }) => (
            <Wallet size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="transactions"
        options={{
          title: 'Transactions',
          tabBarIcon: ({ color, size }) => (
            <ArrowLeftRight size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="budgets"
        options={{
          title: 'Budgets',
          tabBarIcon: ({ color, size }) => (
            <PieChart size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="savings"
        options={{
          title: 'Savings',
          tabBarIcon: ({ color, size }) => (
            <PiggyBank size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  )
}
