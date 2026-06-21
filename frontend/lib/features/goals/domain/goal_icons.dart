import 'package:flutter/material.dart';

/// Curated Material icons a goal can use, keyed by a stable string that is
/// persisted on the backend. Keep keys stable; only ever append new ones.
const Map<String, IconData> kGoalIcons = {
  'savings': Icons.savings_rounded,
  'car': Icons.directions_car_rounded,
  'home': Icons.home_rounded,
  'flight': Icons.flight_takeoff_rounded,
  'school': Icons.school_rounded,
  'health': Icons.favorite_rounded,
  'gift': Icons.card_giftcard_rounded,
  'devices': Icons.devices_rounded,
  'shield': Icons.shield_rounded,
  'celebration': Icons.celebration_rounded,
  'pets': Icons.pets_rounded,
  'star': Icons.star_rounded,
};

/// Fallback icon key used for new goals and unknown stored keys.
const String kDefaultGoalIcon = 'savings';

/// Resolves a stored icon key to its [IconData], falling back when unknown so a
/// future-added key never crashes an older client.
IconData goalIconData(String key) => kGoalIcons[key] ?? Icons.savings_rounded;
