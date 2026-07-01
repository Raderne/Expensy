import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final String id;
  final String email;
  final String name;

  /// Starting bank balance the user holds outside their logged transactions.
  /// The dashboard shows `openingBalance + SUM(transactions)`. May be negative.
  final double openingBalance;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.openingBalance = 0,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
    openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'openingBalance': openingBalance,
  };

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    double? openingBalance,
  }) => AuthUser(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    openingBalance: openingBalance ?? this.openingBalance,
  );

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.name == name &&
      other.openingBalance == openingBalance;

  @override
  int get hashCode => Object.hash(id, email, name, openingBalance);
}
