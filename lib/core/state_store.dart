import 'dart:convert';
import 'dart:io';

import 'helpers.dart';
import 'models.dart';
import '../net/frame.dart';

class AppState {
  Profile profile;
  List<Conversation> conversations;
  Map<String, Peer> peers;
  Map<String, List<Frame>> outbox;

  AppState({
    required this.profile,
    List<Conversation>? conversations,
    Map<String, Peer>? peers,
    Map<String, List<Frame>>? outbox,
  })  : conversations = conversations ?? [],
        peers = peers ?? {},
        outbox = outbox ?? {};

  Map<String, dynamic> toJson() {
    final convs = List<Conversation>.from(conversations)
      ..sort((a, b) => a.id.compareTo(b.id));
    final peersJson = <String, dynamic>{};
    for (final entry in peers.entries) {
      peersJson[entry.key] = entry.value.toJson();
    }
    final outboxJson = <String, dynamic>{};
    for (final entry in outbox.entries) {
      if (entry.value.isEmpty) continue;
      outboxJson[entry.key] = entry.value.map((f) => f.toJson()).toList();
    }
    return {
      'profile': profile.toJson(),
      'conversations': convs.map((c) => c.toJson()).toList(),
      if (peersJson.isNotEmpty) 'peers': peersJson,
      if (outboxJson.isNotEmpty) 'outbox': outboxJson,
      'savedAt': rfc3339(DateTime.now()),
    };
  }

  factory AppState.fromJson(Map<String, dynamic> m, Profile fallbackProfile) {
    final profileRaw = m['profile'];
    final profile = profileRaw is Map
        ? Profile.fromJson(Map<String, dynamic>.from(profileRaw))
        : fallbackProfile;
    final conversations = <Conversation>[];
    final rawConvs = m['conversations'];
    if (rawConvs is List) {
      for (final c in rawConvs) {
        if (c is Map) {
          final conv = Conversation.fromJson(Map<String, dynamic>.from(c));
          if (conv.id.isNotEmpty) conversations.add(conv);
        }
      }
    }
    final peers = <String, Peer>{};
    final rawPeers = m['peers'];
    if (rawPeers is Map) {
      for (final entry in rawPeers.entries) {
        if (entry.value is Map) {
          final peer =
              Peer.fromJson(Map<String, dynamic>.from(entry.value as Map));
          if (peer.id.isNotEmpty) {
            peer.connected = false;
            peers[peer.id] = peer;
          }
        }
      }
    }
    final outbox = <String, List<Frame>>{};
    final rawOutbox = m['outbox'];
    if (rawOutbox is Map) {
      for (final entry in rawOutbox.entries) {
        final list = entry.value;
        if (list is! List) continue;
        final frames = <Frame>[];
        for (final f in list) {
          if (f is! Map) continue;
          try {
            frames.add(Frame.fromJson(Map<String, dynamic>.from(f)));
          } catch (_) {}
        }
        if (frames.isNotEmpty) {
          outbox[entry.key.toString()] = frames;
        }
      }
    }
    return AppState(
      profile: profile,
      conversations: conversations,
      peers: peers,
      outbox: outbox,
    );
  }
}

class StateStore {
  final String path;
  StateStore(this.path);

  Future<AppState> load(Profile fallbackProfile) async {
    final file = File(path);
    if (!await file.exists()) {
      return AppState(profile: fallbackProfile);
    }
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return AppState(profile: fallbackProfile);
      return AppState.fromJson(
        Map<String, dynamic>.from(raw),
        fallbackProfile,
      );
    } catch (_) {
      return AppState(profile: fallbackProfile);
    }
  }

  Future<void> save(AppState state) async {
    final data = const JsonEncoder.withIndent('  ').convert(state.toJson());
    await writeAtomic(path, utf8.encode(data));
  }
}
