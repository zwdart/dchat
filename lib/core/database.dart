import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class StoreStats {
  final int conversations;
  final int messages;
  final int bytes;
  final DateTime? oldest;
  final DateTime? newest;
  final String path;

  StoreStats({
    required this.conversations,
    required this.messages,
    required this.bytes,
    this.oldest,
    this.newest,
    required this.path,
  });
}

class MessageDatabase {
  final String path;
  Database? _db;

  MessageDatabase(this.path);

  Future<void> open() async {
    if (_db != null) return;
    await Directory(p.dirname(path)).create(recursive: true);
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
        await db.execute('PRAGMA busy_timeout = 5000');
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _create(db);
      },
      onOpen: (db) async {
        await _create(db);
      },
    );
  }

  Future<void> _create(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS messages (
  seq          INTEGER PRIMARY KEY AUTOINCREMENT,
  id           TEXT    NOT NULL,
  conv_id      TEXT    NOT NULL,
  sender_id    TEXT    NOT NULL,
  sender_name  TEXT    NOT NULL DEFAULT '',
  kind         TEXT    NOT NULL DEFAULT 'text',
  text         TEXT    NOT NULL DEFAULT '',
  file_name    TEXT,
  file_size    INTEGER NOT NULL DEFAULT 0,
  file_mime    TEXT,
  file_url     TEXT,
  file_token   TEXT,
  file_path    TEXT,
  file_width   INTEGER NOT NULL DEFAULT 0,
  file_height  INTEGER NOT NULL DEFAULT 0,
  sent_at      INTEGER NOT NULL,
  edited_at    INTEGER,
  status       TEXT    NOT NULL DEFAULT '',
  delivered    INTEGER NOT NULL DEFAULT 0,
  read         INTEGER NOT NULL DEFAULT 0,
  recalled     INTEGER NOT NULL DEFAULT 0,
  UNIQUE(conv_id, id)
)''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS messages_conv_time ON messages(conv_id, sent_at, seq)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS messages_conv_sender ON messages(conv_id, sender_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS messages_time ON messages(sent_at)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  }

  Future<List<Message>> loadMessages(String convId) async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      'messages',
      where: 'conv_id = ?',
      whereArgs: [convId],
      orderBy: 'sent_at, seq',
    );
    return rows.map(_fromRow).toList();
  }

  Message _fromRow(Map<String, Object?> r) {
    final kindName = (r['kind'] as String?) ?? 'text';
    MessageKind kind;
    switch (kindName) {
      case 'image':
        kind = MessageKind.image;
        break;
      case 'file':
        kind = MessageKind.file;
        break;
      case 'system':
        kind = MessageKind.system;
        break;
      default:
        kind = MessageKind.text;
    }
    final fileName = r['file_name'] as String?;
    FileMeta? file;
    if (fileName != null) {
      file = FileMeta(
        name: fileName,
        size: (r['file_size'] as int?) ?? 0,
        mime: (r['file_mime'] as String?) ?? '',
        url: (r['file_url'] as String?) ?? '',
        token: (r['file_token'] as String?) ?? '',
        path: (r['file_path'] as String?) ?? '',
        width: (r['file_width'] as int?) ?? 0,
        height: (r['file_height'] as int?) ?? 0,
      );
    }
    final sentAt = (r['sent_at'] as int?) ?? 0;
    final edited = r['edited_at'] as int?;
    return Message(
      id: (r['id'] as String?) ?? '',
      convId: (r['conv_id'] as String?) ?? '',
      senderId: (r['sender_id'] as String?) ?? '',
      senderName: (r['sender_name'] as String?) ?? '',
      kind: kind,
      text: (r['text'] as String?) ?? '',
      file: file,
      sentAt: DateTime.fromMillisecondsSinceEpoch(sentAt),
      editedAt:
          edited == null ? null : DateTime.fromMillisecondsSinceEpoch(edited),
      status: (r['status'] as String?) ?? '',
      delivered: ((r['delivered'] as int?) ?? 0) != 0,
      read: ((r['read'] as int?) ?? 0) != 0,
      recalled: ((r['recalled'] as int?) ?? 0) != 0,
    );
  }

  Future<void> saveMessages(String convId, List<Message> messages) async {
    final db = _db;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('messages', where: 'conv_id = ?', whereArgs: [convId]);
      final batch = txn.batch();
      for (final m in messages) {
        batch.insert(
          'messages',
          {
            'id': m.id,
            'conv_id': convId,
            'sender_id': m.senderId,
            'sender_name': m.senderName,
            'kind': m.kind.name,
            'text': m.text,
            'file_name': m.file?.name,
            'file_size': m.file?.size ?? 0,
            'file_mime': m.file?.mime,
            'file_url': m.file?.url,
            'file_token': m.file?.token,
            'file_path': m.file?.path,
            'file_width': m.file?.width ?? 0,
            'file_height': m.file?.height ?? 0,
            'sent_at': m.sentAt.millisecondsSinceEpoch,
            'edited_at': m.editedAt?.millisecondsSinceEpoch,
            'status': m.status,
            'delivered': m.delivered ? 1 : 0,
            'read': m.read ? 1 : 0,
            'recalled': m.recalled ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteConversation(String convId) async {
    final db = _db;
    if (db == null) return;
    await db.delete('messages', where: 'conv_id = ?', whereArgs: [convId]);
  }

  Future<void> clearAll() async {
    final db = _db;
    if (db == null) return;
    await db.delete('messages');
  }

  Future<StoreStats> stats() async {
    final db = _db;
    if (db == null) {
      return StoreStats(
          conversations: 0, messages: 0, bytes: 0, path: path);
    }
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT conv_id) AS c, COUNT(*) AS n, '
      'MIN(sent_at) AS oldest, MAX(sent_at) AS newest FROM messages',
    );
    final row = rows.isNotEmpty ? rows.first : <String, Object?>{};
    var bytes = 0;
    for (final f in [path, '$path-wal', '$path-shm']) {
      try {
        final file = File(f);
        if (await file.exists()) bytes += await file.length();
      } catch (_) {}
    }
    final oldest = row['oldest'] as int?;
    final newest = row['newest'] as int?;
    return StoreStats(
      conversations: (row['c'] as int?) ?? 0,
      messages: (row['n'] as int?) ?? 0,
      bytes: bytes,
      oldest:
          oldest == null ? null : DateTime.fromMillisecondsSinceEpoch(oldest),
      newest:
          newest == null ? null : DateTime.fromMillisecondsSinceEpoch(newest),
      path: path,
    );
  }

  Future<void> vacuum() async {
    final db = _db;
    if (db == null) return;
    await db.execute('VACUUM');
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) {
      try {
        await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (_) {}
      await db.close();
    }
  }
}
