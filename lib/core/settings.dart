import 'dart:convert';
import 'dart:io';

import 'helpers.dart';
import 'models.dart';

class Settings {
  String appearance;
  String language;
  Presence status;
  bool notifications;
  bool autoDownloadImages;
  bool closeToTray;
  bool discovery;
  int port;
  int transferPort;
  String downloadDir;
  String shareDir;
  String uploadDir;
  int sharePort;
  bool shareOnStart;
  bool screenshotEnabled;
  bool screenshotIncludeChat;
  String screenshotIncludeShortcut;
  String screenshotExcludeShortcut;
  String screenshotDir;
  bool screenshotCursor;
  bool haptics;
  bool notifyPreview;
  bool keepAwake;

  Settings({
    this.appearance = 'system',
    this.language = 'system',
    this.status = Presence.online,
    this.notifications = true,
    this.autoDownloadImages = true,
    this.closeToTray = true,
    this.discovery = true,
    this.port = 42224,
    this.transferPort = 42225,
    this.downloadDir = '',
    this.shareDir = '',
    this.uploadDir = '',
    this.sharePort = 42230,
    this.shareOnStart = false,
    this.screenshotEnabled = true,
    this.screenshotIncludeChat = true,
    this.screenshotIncludeShortcut = '',
    this.screenshotExcludeShortcut = '',
    this.screenshotDir = '',
    this.screenshotCursor = true,
    this.haptics = true,
    this.notifyPreview = true,
    this.keepAwake = true,
  });

  Map<String, dynamic> toJson() => {
        'appearance': appearance,
        if (language.isNotEmpty) 'language': language,
        'status': presenceValue(status),
        'notifications': notifications,
        'autoDownloadImages': autoDownloadImages,
        'closeToTray': closeToTray,
        'discovery': discovery,
        'port': port,
        'transferPort': transferPort,
        if (downloadDir.isNotEmpty) 'downloadDir': downloadDir,
        if (shareDir.isNotEmpty) 'shareDir': shareDir,
        if (uploadDir.isNotEmpty) 'uploadDir': uploadDir,
        'sharePort': sharePort,
        'shareOnStart': shareOnStart,
        'screenshotEnabled': screenshotEnabled,
        'screenshotIncludeChat': screenshotIncludeChat,
        if (screenshotIncludeShortcut.isNotEmpty)
          'screenshotIncludeShortcut': screenshotIncludeShortcut,
        if (screenshotExcludeShortcut.isNotEmpty)
          'screenshotExcludeShortcut': screenshotExcludeShortcut,
        if (screenshotDir.isNotEmpty) 'screenshotDir': screenshotDir,
        'screenshotCursor': screenshotCursor,
        'haptics': haptics,
        'notifyPreview': notifyPreview,
        'keepAwake': keepAwake,
      };

  factory Settings.fromJson(Map<String, dynamic> m, Settings defaults) {
    final s = Settings(
      appearance: asString(m['appearance'], defaults.appearance),
      language: asString(m['language'], defaults.language),
      status: presenceFrom(m['status']),
      notifications: asBool(m['notifications'], defaults.notifications),
      autoDownloadImages:
          asBool(m['autoDownloadImages'], defaults.autoDownloadImages),
      closeToTray: asBool(m['closeToTray'], defaults.closeToTray),
      discovery: asBool(m['discovery'], defaults.discovery),
      port: asInt(m['port'], defaults.port),
      transferPort: asInt(m['transferPort'], defaults.transferPort),
      downloadDir: asString(m['downloadDir']),
      shareDir: asString(m['shareDir']),
      uploadDir: asString(m['uploadDir']),
      sharePort: asInt(m['sharePort'], defaults.sharePort),
      shareOnStart: asBool(m['shareOnStart'], defaults.shareOnStart),
      screenshotEnabled:
          asBool(m['screenshotEnabled'], defaults.screenshotEnabled),
      screenshotIncludeChat:
          asBool(m['screenshotIncludeChat'], defaults.screenshotIncludeChat),
      screenshotIncludeShortcut:
          asString(m['screenshotIncludeShortcut'], defaults.screenshotIncludeShortcut),
      screenshotExcludeShortcut:
          asString(m['screenshotExcludeShortcut'], defaults.screenshotExcludeShortcut),
      screenshotDir: asString(m['screenshotDir']),
      screenshotCursor: asBool(m['screenshotCursor'], defaults.screenshotCursor),
      haptics: asBool(m['haptics'], defaults.haptics),
      notifyPreview: asBool(m['notifyPreview'], defaults.notifyPreview),
      keepAwake: asBool(m['keepAwake'], defaults.keepAwake),
    );
    if (s.port == 0) s.port = 42224;
    if (s.transferPort == 0) s.transferPort = 42225;
    if (s.sharePort == 0) s.sharePort = 42230;
    if (s.language.isEmpty) s.language = 'system';
    if (s.status == Presence.offline) s.status = Presence.online;
    if (s.downloadDir.isEmpty) s.downloadDir = defaults.downloadDir;
    if (s.screenshotDir.isEmpty) s.screenshotDir = defaults.screenshotDir;
    return s;
  }
}

class SettingsStore {
  final String path;
  SettingsStore(this.path);

  Future<Settings> load(Settings defaults) async {
    final f = File(path);
    if (!await f.exists()) return defaults;
    try {
      final raw = jsonDecode(await f.readAsString());
      if (raw is! Map) return defaults;
      return Settings.fromJson(Map<String, dynamic>.from(raw), defaults);
    } catch (_) {
      return defaults;
    }
  }

  Future<void> save(Settings s) async {
    await writeAtomic(path, utf8.encode(const JsonEncoder.withIndent('  ').convert(s.toJson())));
  }
}
