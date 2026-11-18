import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update/update_models.dart';
import '../services/update/update_platform.dart';
import '../services/update/update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  noAsset,
  downloading,
  downloaded,
  error,
}

class UpdateViewModel extends ChangeNotifier {
  final UpdateService service;
  final UpdatePlatform platform;
  final String? _architecture;

  UpdateStatus status = UpdateStatus.idle;
  UpdateCheckResult? result;
  String? error;
  String localVersion = '';
  int received = 0;
  int total = 0;
  File? downloadedFile;
  bool _disposed = false;

  UpdateViewModel({
    UpdateService? service,
    UpdatePlatform? platform,
    String? architecture,
  })  : service = service ?? UpdateService(),
        platform = platform ?? UpdatePlatform.current,
        // ignore: prefer_initializing_formals
        _architecture = architecture;

  String get architecture => _architecture ?? platform.architecture;

  bool get busy =>
      status == UpdateStatus.checking || status == UpdateStatus.downloading;

  double get progress {
    if (total <= 0) return 0;
    return (received / total).clamp(0.0, 1.0);
  }

  String? get link => result?.downloadUrl;

  Future<void> check({String? localVersion, String? localBuild}) async {
    if (busy) return;
    status = UpdateStatus.checking;
    error = null;
    result = null;
    downloadedFile = null;
    received = 0;
    total = 0;
    _notify();

    var version = localVersion?.trim() ?? '';
    var build = localBuild?.trim() ?? '';
    try {
      if (version.isEmpty) {
        final info = await PackageInfo.fromPlatform();
        version = info.version;
        if (build.isEmpty) build = info.buildNumber;
      }
      this.localVersion = version;
      final checked = await service.check(
        localVersion: version,
        localBuild: build,
        platform: platform,
        architecture: architecture,
      );
      result = checked;
      if (!checked.hasUpdate) {
        status = UpdateStatus.upToDate;
      } else if (!checked.hasAsset) {
        status = UpdateStatus.noAsset;
      } else {
        status = UpdateStatus.available;
      }
    } catch (e) {
      status = UpdateStatus.error;
      error = e is UpdateException ? e.message : e.toString();
    }
    _notify();
  }

  Future<void> download() async {
    final asset = result?.asset;
    if (asset == null || status == UpdateStatus.downloading) return;
    status = UpdateStatus.downloading;
    error = null;
    received = 0;
    total = asset.size;
    _notify();
    try {
      final directory = await UpdateService.defaultDownloadDirectory();
      downloadedFile = await service.download(
        asset,
        directory: directory,
        onProgress: (r, t) {
          received = r;
          total = t;
          _notify();
        },
      );
      status = UpdateStatus.downloaded;
    } catch (e) {
      status = UpdateStatus.error;
      error = e is UpdateException ? e.message : e.toString();
    }
    _notify();
  }

  Future<String?> openDownloaded() async {
    final file = downloadedFile;
    if (file == null) return '安装包尚未下载';
    try {
      await service.openDownloaded(file);
      return null;
    } catch (e) {
      return e is UpdateException ? e.message : e.toString();
    }
  }

  Future<bool> copyLink() async {
    final value = link;
    if (value == null || value.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: value));
    return true;
  }

  Future<String?> openInBrowser() async {
    final value = link;
    if (value == null || value.isEmpty) return '没有可用的下载链接';
    try {
      final ok = await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
      return ok ? null : '无法打开浏览器';
    } catch (_) {
      return '无法打开浏览器';
    }
  }

  void reset() {
    if (busy) return;
    status = UpdateStatus.idle;
    result = null;
    error = null;
    downloadedFile = null;
    received = 0;
    total = 0;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
