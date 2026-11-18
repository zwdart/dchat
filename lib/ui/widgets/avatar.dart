import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../theme.dart';

Uint8List? avatarBytes(String encoded) {
  if (encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length > 1) {
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
  final runes = trimmed.runes.toList();
  return String.fromCharCodes(runes.take(1)).toUpperCase();
}

class PeerAvatar extends StatelessWidget {
  final String name;
  final String avatar;
  final Presence status;
  final double size;
  final bool showStatus;
  final bool isGroup;

  const PeerAvatar({
    super.key,
    required this.name,
    this.avatar = '',
    this.status = Presence.offline,
    this.size = 44,
    this.showStatus = true,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final bytes = avatarBytes(avatar);
    final bg = isGroup ? c.accent : avatarColor(name, c);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes != null
                ? Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => _fallback(c, bg),
                  )
                : _fallback(c, bg),
          ),
          if (showStatus && !isGroup)
            Positioned(
              right: 0,
              bottom: 0,
              child: StatusDot(
                status: status,
                size: (size * 0.27).clamp(9.0, 14.0),
                borderColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(AppColors c, Color bg) {
    return Center(
      child: Text(
        _initials(name),
        style: TextStyle(
          color: bg,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final Presence status;
  final double size;
  final Color? borderColor;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 10,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: presenceColor(status, c),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Theme.of(context).scaffoldBackgroundColor,
          width: size > 10 ? 2 : 1.6,
        ),
      ),
    );
  }
}
