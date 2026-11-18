import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Platforms supported by the updater.
///
/// The caller decides the target platform explicitly through
/// [UpdateService.check] and [UpdateService.selectAsset]. This keeps asset
/// selection deterministic and easy to test for every release platform.
enum UpdatePlatform {
  android,
  ios,
  macOS,
  windows,
  linux;

  static UpdatePlatform get current {
    if (kIsWeb) return UpdatePlatform.linux;
    if (Platform.isAndroid) return UpdatePlatform.android;
    if (Platform.isIOS) return UpdatePlatform.ios;
    if (Platform.isMacOS) return UpdatePlatform.macOS;
    if (Platform.isWindows) return UpdatePlatform.windows;
    return UpdatePlatform.linux;
  }

  String get id => name;

  /// Best-effort host CPU architecture used to pick between `x64`, `arm64`
  /// and similar packages in the same release.
  String get architecture {
    if (kIsWeb) return '';
    final abi = ffi.Abi.current().toString().toLowerCase();
    if (abi.contains('arm64')) return 'arm64';
    if (abi.contains('arm')) return 'arm';
    if (abi.contains('x64') || abi.contains('amd64')) return 'x64';
    if (abi.contains('ia32') || abi.contains('x86')) return 'x86';
    return '';
  }

  /// Asset extensions that can be installed or unpacked on this platform.
  List<String> get extensions => switch (this) {
        UpdatePlatform.android => const ['.apk'],
        UpdatePlatform.ios => const ['.ipa', '.zip'],
        UpdatePlatform.macOS => const ['.dmg', '.pkg', '.zip'],
        UpdatePlatform.windows => const ['.exe', '.msi', '.zip'],
        UpdatePlatform.linux => const [
            '.appimage',
            '.deb',
            '.rpm',
            '.pkg.tar.zst',
            '.tar.gz',
            '.tar.xz',
            '.zip',
          ],
      };

  /// Name fragments used to avoid selecting another platform's package.
  List<String> get nameHints => switch (this) {
        UpdatePlatform.android => const ['android', 'apk'],
        UpdatePlatform.ios => const ['ios', 'iphone', 'ipad', 'ipa'],
        UpdatePlatform.macOS => const ['macos', 'mac', 'darwin', 'dmg'],
        UpdatePlatform.windows => const ['windows', 'win', 'win64', 'exe'],
        UpdatePlatform.linux => const ['linux', 'appimage', 'deb', 'rpm'],
      };

  /// Architecture hints that should receive a small preference.
  List<String> get architectureHints => switch (this) {
        UpdatePlatform.android => const ['universal', 'arm64', 'aarch64', 'arm'],
        UpdatePlatform.ios => const ['universal', 'arm64'],
        UpdatePlatform.macOS => const ['universal', 'arm64', 'x64', 'x86_64'],
        UpdatePlatform.windows => const ['x64', 'x86_64', 'amd64', 'win64'],
        UpdatePlatform.linux => const ['x64', 'x86_64', 'amd64'],
      };
}
