/**
 * Modular Sync Queue Persistence Manager
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

import 'dart:convert';
import '../errors/app_error_codes.dart';

enum SyncItemStatus { pending, processing, synced, failed }

class ModularSyncItem {
  final String id;
  final String entityType;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  SyncItemStatus status;
  int retryCount;
  final DateTime createdAt;
  DateTime? updatedAt;

  ModularSyncItem({
    required this.id,
    required this.entityType,
    required this.endpoint,
    required this.method,
    required this.payload,
    this.status = SyncItemStatus.pending,
    this.retryCount = 0,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'status': status.name,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ModularSyncItem.fromMap(Map<String, dynamic> map) {
    return ModularSyncItem(
      id: map['id'] as String,
      entityType: map['entityType'] as String,
      endpoint: map['endpoint'] as String,
      method: map['method'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      status: SyncItemStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SyncItemStatus.pending,
      ),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ModularSyncItem.fromJson(String source) =>
      ModularSyncItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

abstract class ISyncStorageAdapter {
  Future<void> save(String key, String rawData);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class InMemorySyncStorageAdapter implements ISyncStorageAdapter {
  final Map<String, String> _store = {};
  bool failNextWrite = false;

  @override
  Future<void> save(String key, String rawData) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw Exception('Simulated disk I/O failure');
    }
    _store[key] = rawData;
  }

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> delete(String key) async => _store.remove(key);
}

class SyncQueuePersistence {
  static const String defaultStorageKey = 'modular_sync_queue_v1';
  final ISyncStorageAdapter storage;
  final String storageKey;
  final List<ModularSyncItem> _queue = [];

  SyncQueuePersistence({
    ISyncStorageAdapter? storage,
    this.storageKey = defaultStorageKey,
  }) : storage = storage ?? InMemorySyncStorageAdapter();

  List<ModularSyncItem> get items => List.unmodifiable(_queue);
  int get count => _queue.length;
  int get pendingCount =>
      _queue.where((i) => i.status == SyncItemStatus.pending).length;

  Future<void> enqueue(ModularSyncItem item) async {
    // Deduplication check: if item ID exists, replace payload or ignore
    final existingIndex = _queue.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _queue[existingIndex] = item;
    } else {
      _queue.add(item);
    }
    await persist();
  }

  ModularSyncItem? peek() {
    return _queue.cast<ModularSyncItem?>().firstWhere(
          (i) => i?.status == SyncItemStatus.pending,
          orElse: () => null,
        );
  }

  Future<void> updateStatus(String itemId, SyncItemStatus newStatus) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      _queue[index].status = newStatus;
      _queue[index].updatedAt = DateTime.now();
      await persist();
    }
  }

  Future<void> remove(String itemId) async {
    _queue.removeWhere((i) => i.id == itemId);
    await persist();
  }

  Future<void> clear() async {
    _queue.clear();
    await persist();
  }

  Future<void> persist() async {
    try {
      final serializedList = _queue.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(serializedList);
      await storage.save(storageKey, jsonString);
    } catch (e) {
      throw AppException(
        code: AppErrorCode.SYNC_QUEUE_PERSISTENCE_FAILED,
        message:
            'Could not serialize or save sync queue to persistence storage',
        details: e.toString(),
      );
    }
  }

  Future<void> restore() async {
    try {
      final raw = await storage.read(storageKey);
      _queue.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final entry in decoded) {
          _queue.add(
              ModularSyncItem.fromMap(Map<String, dynamic>.from(entry as Map)));
        }
      }
    } catch (e) {
      throw AppException(
        code: AppErrorCode.SYNC_ITEM_CORRUPTED,
        message: 'Failed to restore sync queue from storage snapshot',
        details: e.toString(),
      );
    }
  }
}
