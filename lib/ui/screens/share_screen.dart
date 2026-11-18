import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../state/chat_controller.dart';
import '../adaptive.dart';
import '../dialogs/dialogs.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'qr_scanner_screen.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ChatController>();
    final colors = appColors(context);
    final running = c.shareRunning;
    final urls = c.shareUrls();

    return Scaffold(
      appBar: DchatAppBar(
        title: Text(L10n.instance.tr('文件共享')),
        actions: [
          if (AppPlatform.isMobile)
            IconAction(
              icon: Icons.qr_code_scanner,
              tooltip: L10n.instance.tr('扫描共享二维码'),
              onPressed: () => _scan(context, c),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: running
                    ? [
                        colors.accent.withValues(alpha: 0.18),
                        colors.accent.withValues(alpha: 0.05),
                      ]
                    : [colors.panel, colors.panel],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: running
                    ? colors.accent.withValues(alpha: 0.28)
                    : colors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: (running ? colors.accent : colors.faint)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        running ? Icons.wifi : Icons.wifi_off,
                        color: running ? colors.accent : colors.faint,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            running ? L10n.instance.tr('正在共享') : L10n.instance.tr('文件共享已关闭'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            running
                                ? trf('端口 %s · 局域网可访问', [c.sharePortActual])
                                : L10n.instance.tr('开启后可通过浏览器下载或上传文件'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdaptiveSwitch(
                      value: running,
                      onChanged: (value) async {
                        if (value) {
                          await c.startShare();
                        } else {
                          await c.stopShare();
                        }
                      },
                    ),
                  ],
                ),
                if (running && urls.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: urls.first,
                        version: QrVersions.auto,
                        size: 190,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final url in urls)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (context.mounted) showAppSnack(context, L10n.instance.tr('已复制链接'));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: colors.background.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link, size: 16, color: colors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.text,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: colors.faint,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(urls.first);
                            if (uri == null) return;
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.open_in_browser, size: 18),
                          label: Text(L10n.instance.tr('打开网页')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final url = c.shareUrl();
                            if (url.isEmpty) return;
                            if (c.activeConvId.isEmpty) {
                              showAppSnack(context, L10n.instance.tr('请先打开一个聊天'));
                              return;
                            }
                            c.sendTextTo(
                              c.activeConvId,
                              '${L10n.instance.tr('我在 zchat 共享了一个目录：')}$url',
                            );
                            showAppSnack(context, L10n.instance.tr('已发送共享链接'));
                          },
                          icon: const Icon(Icons.send_outlined, size: 18),
                          label: Text(L10n.instance.tr('发送到聊天')),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: L10n.instance.tr('共享目录'),
            subtitle: L10n.instance.tr('其他人可以在浏览器中浏览并下载这里的文件。'),
            child: _DirectoryRow(
              icon: Icons.folder_open_outlined,
              label: L10n.instance.tr('目录'),
              value: c.settings.shareDir,
              placeholder: L10n.instance.tr('未选择（仅提供传输下载）'),
              onPick: () => _pickDir(
                context,
                c,
                initial: c.settings.shareDir,
                title: L10n.instance.tr('选择共享目录'),
                onPicked: (dir) => c.setShareDirs(dir, c.settings.uploadDir),
              ),
              onClear: c.settings.shareDir.isEmpty
                  ? null
                  : () => c.setShareDirs('', c.settings.uploadDir),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: L10n.instance.tr('上传目录'),
            subtitle: L10n.instance.tr('开启后，浏览器可以通过上传页面把文件发送到此目录。'),
            child: _DirectoryRow(
              icon: Icons.upload_file_outlined,
              label: L10n.instance.tr('目录'),
              value: c.settings.uploadDir,
              placeholder: L10n.instance.tr('未开启上传'),
              onPick: () => _pickDir(
                context,
                c,
                initial: c.settings.uploadDir,
                title: L10n.instance.tr('选择上传目录'),
                onPicked: (dir) =>
                    c.setShareDirs(c.settings.shareDir, dir),
              ),
              onClear: c.settings.uploadDir.isEmpty
                  ? null
                  : () => c.setShareDirs(c.settings.shareDir, ''),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: L10n.instance.tr('服务设置'),
            child: Column(
              children: [
                InfoRow(
                  label: L10n.instance.tr('共享端口'),
                  value: '${c.settings.sharePort}',
                  trailing: TextButton(
                    onPressed: () async {
                      final value = await promptText(
                        context,
                        title: L10n.instance.tr('修改共享端口'),
                        label: L10n.instance.tr('端口（1024 - 65535）'),
                        initial: '${c.settings.sharePort}',
                      );
                      if (value == null) return;
                      final port = int.tryParse(value);
                      if (port == null || port < 1024 || port > 65535) {
                        if (context.mounted) {
                          showAppSnack(context, L10n.instance.tr('请输入有效端口'));
                        }
                        return;
                      }
                      await c.setSharePort(port);
                    },
                    child: Text(L10n.instance.tr('修改')),
                  ),
                ),
                InfoRow(
                  label: L10n.instance.tr('本机地址'),
                  value: c.localIps.isEmpty ? L10n.instance.tr('未知') : c.localIps.join(', '),
                ),
                InfoRow(
                  label: L10n.instance.tr('状态'),
                  value: running ? L10n.instance.tr('运行中') : L10n.instance.tr('已停止'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: L10n.instance.tr('接收其他设备的文件'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    L10n.instance.tr('扫描其他设备展示的二维码，即可在他们的共享页面下载文件。'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: colors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _scan(context, c),
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(L10n.instance.tr('扫描')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scan(BuildContext context, ChatController c) async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerScreen()),
    );
    if (value == null || !context.mounted) return;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    final manual = await promptText(
      context,
      title: L10n.instance.tr('扫描结果'),
      label: L10n.instance.tr('IP 或 IP:端口'),
      initial: value,
      confirm: L10n.instance.tr('连接'),
    );
    if (manual == null || manual.isEmpty || !context.mounted) return;
    try {
      final peer = await c.manualConnect(manual);
      c.ensureDirect(peer);
      if (context.mounted) showAppSnack(context, trf('已连接 %s', [peer.displayName]));
    } catch (e) {
      if (context.mounted) showAppSnack(context, trf('连接失败：%s', ['$e']));
    }
  }

  Future<void> _pickDir(
    BuildContext context,
    ChatController c, {
    required String initial,
    required String title,
    required Future<void> Function(String) onPicked,
  }) async {
    try {
      // ignore: deprecated_member_use
      final dir = await FilePicker.getDirectoryPath(
        dialogTitle: title,
        initialDirectory: initial.isEmpty ? null : initial,
      );
      if (dir == null || dir.isEmpty) return;
      await onPicked(dir);
    } catch (e) {
      if (context.mounted) showAppSnack(context, trf('无法选择目录：%s', ['$e']));
    }
  }
}

class _DirectoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _DirectoryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final name = value.isEmpty ? '' : p.basename(value);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Icon(icon, size: 19, color: c.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: c.faint)),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? placeholder : (name.isEmpty ? value : name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: value.isEmpty ? c.faint : c.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onPick, child: Text(L10n.instance.tr('选择'))),
        if (onClear != null)
          IconButton(
            tooltip: L10n.instance.tr('清除'),
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 18),
          ),
      ],
    );
  }
}
