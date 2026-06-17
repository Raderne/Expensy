import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';

/// A lightweight person the user splits expenses with. Not an Expensy account —
/// just a name + avatar tint the user manages locally.
@immutable
class Contact {
  final String id;
  final String name;

  /// Optional hex avatar tint (e.g. `#1B45D0`). Falls back to a palette colour
  /// derived from the id when null.
  final String? color;

  /// True while this contact is still queued in the outbox (created offline).
  final bool pending;

  const Contact({
    required this.id,
    required this.name,
    this.color,
    this.pending = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String?,
  );

  /// Resolved avatar colour — the stored hex, or a stable palette pick.
  Color get colorValue {
    final hex = color;
    if (hex != null) return _parseHex(hex);
    final palette = AppColors.categoryPalette;
    return palette[id.hashCode.abs() % palette.length];
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    if (parts.length == 1) return first;
    return '$first${parts.last.characters.first.toUpperCase()}';
  }

  static Color _parseHex(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    return Color(int.parse('FF$h', radix: 16));
  }
}
