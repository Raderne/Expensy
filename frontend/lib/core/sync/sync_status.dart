import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import '../network/server_health.dart';
import 'outbox.dart';
import 'outbox_writer.dart';
import 'sync_engine.dart';

enum SyncConnection { online, offline, waking }

@immutable
class SyncStatus {
  final SyncConnection connection;
  final bool syncing;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;

  const SyncStatus({
    required this.connection,
    required this.syncing,
    required this.pendingCount,
    required this.failedCount,
    required this.lastSyncedAt,
  });

  /// Nothing worth telling the user about: connected, idle, queue empty.
  bool get isClear =>
      connection == SyncConnection.online &&
      !syncing &&
      pendingCount == 0 &&
      failedCount == 0;
}

/// Single source of truth for the sync banner / indicators. Folds together
/// connectivity, the wake-up probe, the engine's syncing flag, and the queue
/// contents.
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final hasNetwork = ref.watch(hasNetworkProvider).value ?? true;
  final wake = ref.watch(serverWakerProvider);
  final engine = ref.watch(syncEngineProvider);
  final pending = ref.watch(pendingWritesProvider).value ?? const [];

  final connection = !hasNetwork
      ? SyncConnection.offline
      : (wake == ServerWakeState.waking
            ? SyncConnection.waking
            : SyncConnection.online);

  return SyncStatus(
    connection: connection,
    syncing: engine.syncing,
    pendingCount: pending.where((e) => e.status == OutboxStatus.pending).length,
    failedCount: pending.where((e) => e.status == OutboxStatus.failed).length,
    lastSyncedAt: engine.lastSyncedAt,
  );
});
