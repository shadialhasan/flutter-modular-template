/**
 * Unit Tests: Sync Queue Persistence & Serialization
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

import 'package:flutter_modular_template/core/errors/app_error_codes.dart';
import 'package:flutter_modular_template/core/sync/sync_queue_persistence.dart';
import 'package:test/test.dart';

void main() {
  group('SyncQueuePersistence Unit Tests', () {
    late InMemorySyncStorageAdapter storage;
    late SyncQueuePersistence queue;

    setUp(() {
      storage = InMemorySyncStorageAdapter();
      queue = SyncQueuePersistence(storage: storage);
    });

    test('enqueue items and maintain FIFO order', () async {
      final item1 = ModularSyncItem(
        id: 'sync_001',
        entityType: 'UserProfile',
        endpoint: '/api/v1/profile',
        method: 'PUT',
        payload: {'name': 'Eng. MHD. Shadi AL-Hasan'},
      );

      final item2 = ModularSyncItem(
        id: 'sync_002',
        entityType: 'Settings',
        endpoint: '/api/v1/settings',
        method: 'POST',
        payload: {'theme': 'dark'},
      );

      await queue.enqueue(item1);
      await queue.enqueue(item2);

      expect(queue.count, equals(2));
      expect(queue.pendingCount, equals(2));

      final peeked = queue.peek();
      expect(peeked?.id, equals('sync_001'));
    });

    test('deduplicates existing item by ID and updates payload', () async {
      final item1 = ModularSyncItem(
        id: 'sync_dup_1',
        entityType: 'Task',
        endpoint: '/api/v1/tasks',
        method: 'POST',
        payload: {'status': 'draft'},
      );
      await queue.enqueue(item1);

      final itemUpdated = ModularSyncItem(
        id: 'sync_dup_1',
        entityType: 'Task',
        endpoint: '/api/v1/tasks',
        method: 'POST',
        payload: {'status': 'published'},
      );
      await queue.enqueue(itemUpdated);

      expect(queue.count, equals(1));
      expect(queue.items.first.payload['status'], equals('published'));
    });

    test('persists queue to storage adapter and restores snapshot successfully',
        () async {
      final item = ModularSyncItem(
        id: 'sync_restore_1',
        entityType: 'Order',
        endpoint: '/api/v1/orders',
        method: 'POST',
        payload: {'orderId': 991, 'amount': 150.0},
      );

      await queue.enqueue(item);
      final rawSnapshot = await storage.read(queue.storageKey);
      expect(rawSnapshot, isNotNull);
      expect(rawSnapshot, contains('sync_restore_1'));
      expect(rawSnapshot, contains('Order'));

      // New instance restoring from same storage adapter
      final restoredQueue = SyncQueuePersistence(storage: storage);
      await restoredQueue.restore();

      expect(restoredQueue.count, equals(1));
      expect(restoredQueue.items.first.id, equals('sync_restore_1'));
      expect(restoredQueue.items.first.endpoint, equals('/api/v1/orders'));
      expect(restoredQueue.items.first.status, equals(SyncItemStatus.pending));
    });

    test('updates item status through lifecycle transitions', () async {
      final item = ModularSyncItem(
        id: 'sync_stat_1',
        entityType: 'Log',
        endpoint: '/api/v1/logs',
        method: 'POST',
        payload: {'level': 'INFO'},
      );
      await queue.enqueue(item);

      await queue.updateStatus('sync_stat_1', SyncItemStatus.processing);
      expect(queue.items.first.status, equals(SyncItemStatus.processing));
      expect(queue.pendingCount, equals(0));

      await queue.updateStatus('sync_stat_1', SyncItemStatus.synced);
      expect(queue.items.first.status, equals(SyncItemStatus.synced));

      await queue.remove('sync_stat_1');
      expect(queue.count, equals(0));
    });

    test(
        'throws AppException SYNC_QUEUE_PERSISTENCE_FAILED when storage write fails',
        () async {
      storage.failNextWrite = true;
      final item = ModularSyncItem(
        id: 'sync_fail_1',
        entityType: 'Crash',
        endpoint: '/api/v1/crash',
        method: 'POST',
        payload: {'err': 'fail'},
      );

      expect(
        () => queue.enqueue(item),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            equals(AppErrorCode.SYNC_QUEUE_PERSISTENCE_FAILED),
          ),
        ),
      );
    });
  });
}
