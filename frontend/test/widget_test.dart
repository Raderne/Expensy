import 'package:expensy/app/app.dart';
import 'package:expensy/core/cache/http_cache.dart';
import 'package:expensy/core/sync/outbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into a MaterialApp', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          httpCacheProvider.overrideWithValue(InMemoryHttpCache()),
          outboxProvider.overrideWithValue(InMemoryOutbox()),
        ],
        child: const ExpensyApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
