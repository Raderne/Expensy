import React from 'react';
import { Redirect, Tabs } from 'expo-router';
import { LayoutDashboard, Wallet, ArrowLeftRight, PieChart, PiggyBank, BarChart2, CreditCard, Settings } from 'lucide-react-native';
import { useAuthStore } from '@/store/auth.store';
import { Colors } from '@/constants/colors';

export default function AppLayout() {
  const { isAuthenticated, isInitialized } = useAuthStore();

  if (!isAuthenticated && isInitialized) {
    return <Redirect href='/(auth)/login' />;
  }

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Colors.purple[500],
        tabBarInactiveTintColor: Colors.text.muted,
        tabBarStyle: {
          backgroundColor: Colors.bg.elevated,
          borderTopColor: Colors.border.subtle,
          borderTopWidth: 1,
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '500',
        },
      }}
    >
      <Tabs.Screen
        name='index'
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ color, size }) => <LayoutDashboard size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name='wallets'
        options={{
          title: 'Wallets',
          tabBarIcon: ({ color, size }) => <Wallet size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name='budgets'
        options={{
          title: 'Budgets',
          tabBarIcon: ({ color, size }) => <PieChart size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name='savings'
        options={{
          title: 'Savings',
          tabBarIcon: ({ color, size }) => <PiggyBank size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name='subscriptions'
        options={{
          title: 'Subscriptions',
          tabBarIcon: ({ color, size }) => <CreditCard size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name='analytics'
        options={{
          title: 'Analytics',
          tabBarIcon: ({ color, size }) => <BarChart2 size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name='settings'
        options={{
          title: 'Settings',
          tabBarIcon: ({ color, size }) => <Settings size={size} color={color} />,
        }}
      />
      {/* Modal screen — hidden from the tab bar */}
      <Tabs.Screen
        name='add-expense'
        options={{
          href: null, // hides from tab bar
        }}
      />
      {/* Notifications — accessible via bell icon on Dashboard, not a tab */}
      <Tabs.Screen
        name='notifications'
        options={{
          href: null, // hides from tab bar
        }}
      />
    </Tabs>
  );
}
