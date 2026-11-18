import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake while the app is in the foreground.
///
/// The service is idempotent: repeated calls with the same state do not touch
/// the platform channel. Errors (for example when the platform is unsupported)
/// are swallowed so that they never break the UI.
class KeepAwakeService {
  KeepAwakeService._();

  static final KeepAwakeService instance = KeepAwakeService._();

  bool? _applied;

  bool get supported => !kIsWeb;

  Future<void> sync({required bool enabled, required bool foreground}) async {
    final shouldEnable = enabled && foreground;
    if (_applied == shouldEnable) return;
    _applied = shouldEnable;
    try {
      await WakelockPlus.toggle(enable: shouldEnable);
    } catch (_) {
      _applied = null;
    }
  }

  Future<void> release() async {
    if (_applied == false) return;
    _applied = false;
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }
}
