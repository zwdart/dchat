import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n.dart';

class ImageViewerScreen extends StatelessWidget {
  final String path;
  final String? title;

  const ImageViewerScreen({
    super.key,
    required this.path,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? L10n.instance.tr('图片'),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: L10n.instance.tr('分享'),
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(path)], text: title),
            ),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.7,
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  L10n.instance.tr('无法打开图片'),
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
