import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/sync/outbox.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/contact.dart';

/// Offline-first contacts data source. Reads hit the API directly; writes are
/// queued through the outbox (like categories) so a contact created offline is
/// usable immediately, and any split referencing its temp id is remapped to the
/// real id by the SyncEngine on replay.
class ContactsRepository {
  final Dio _dio;
  final OutboxWriter _outbox;
  const ContactsRepository(this._dio, this._outbox);

  Future<List<Contact>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/contacts');
    _ensureOk(res);
    final list = res.data!['contacts'] as List<dynamic>;
    return list.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Queues a create and returns the optimistic row (with a temp id).
  Future<Contact> create({required String name, String? color}) async {
    final tempId = _outbox.newTempId();
    await _outbox.enqueue(
      kind: 'contactCreate',
      method: 'POST',
      path: '/me/contacts',
      tempId: tempId,
      body: {'name': name, 'color': ?color},
    );
    return Contact(id: tempId, name: name, color: color, pending: true);
  }

  Future<void> update({
    required String id,
    String? name,
    String? color,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (color != null) body['color'] = color;
    await _outbox.enqueue(
      kind: 'contactUpdate',
      method: 'PUT',
      path: '/me/contacts/$id',
      body: body,
    );
  }

  Future<void> delete(String id) async {
    await _outbox.enqueue(
      kind: 'contactDelete',
      method: 'DELETE',
      path: '/me/contacts/$id',
    );
  }

  void _ensureOk(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    throw ContactsApiException(
      status: status,
      message: (data is Map ? data['title']?.toString() : null) ?? 'Request failed',
    );
  }
}

class ContactsApiException implements Exception {
  final int status;
  final String message;
  const ContactsApiException({required this.status, required this.message});

  @override
  String toString() => 'ContactsApiException($status): $message';
}

final contactsRepositoryProvider = Provider<ContactsRepository>(
  (ref) => ContactsRepository(ref.watch(dioProvider), ref.watch(outboxWriterProvider)),
);

/// Server contacts, gated on auth. Refetched when invalidated after a sync.
final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.hasValue || auth.value is! AuthAuthenticated) return const [];
  return ref.watch(contactsRepositoryProvider).list();
});

/// Server contacts overlaid with still-pending outbox writes: optimistic creates
/// appended, queued deletes hidden — mirrors [categoriesViewProvider].
final contactsViewProvider = Provider<AsyncValue<List<Contact>>>((ref) {
  final base = ref.watch(contactsProvider);
  final pending = ref.watch(pendingWritesProvider).value ?? const [];
  return base.whenData((contacts) => overlayContacts(contacts, pending));
});

/// Pure overlay used by [contactsViewProvider].
List<Contact> overlayContacts(List<Contact> base, List<OutboxEntry> pending) {
  if (pending.isEmpty) return base;
  final deleted = <String>{};
  final creates = <Contact>[];
  for (final e in pending) {
    switch (e.kind) {
      case 'contactDelete':
        deleted.add(e.path.split('/').last);
      case 'contactCreate':
        final b = e.body ?? const {};
        creates.add(
          Contact(
            id: e.tempId ?? e.id,
            name: (b['name'] as String?) ?? '',
            color: b['color'] as String?,
            pending: true,
          ),
        );
    }
  }
  return [
    ...base.where((c) => !deleted.contains(c.id)),
    ...creates,
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
