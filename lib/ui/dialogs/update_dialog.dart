import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/i18n.dart';
import '../../services/update/update_platform.dart';
import '../../state/update_view_model.dart';
import '../theme.dart';
import 'dialogs.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateViewModel model) {
  return showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider<UpdateViewModel>.value(
      value: model,
      child: const _UpdateDialog(),
    ),
  );
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<UpdateViewModel>();
    final colors = appColors(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update_alt, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(L10n.instance.tr('版本更新'))),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(child: _body(context, model)),
        ),
      ),
      actions: _actions(context, model),
    );
  }

  Widget _body(BuildContext context, UpdateViewModel model) {
    final colors = appColors(context);
    switch (model.status) {
      case UpdateStatus.idle:
        return Text(L10n.instance.tr('点击检查更新，从发布服务器获取最新版本信息。'));
      case UpdateStatus.checking:
        return Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(L10n.instance.tr('正在检查更新…'))),
          ],
        );
      case UpdateStatus.upToDate:
        return _message(
          context,
          icon: Icons.check_circle_outline,
          color: colors.accent,
          title: L10n.instance.tr('已是最新版本'),
          detail: trf('当前版本：%s', [model.result?.localVersion.toString() ?? model.localVersion]),
        );
      case UpdateStatus.noAsset:
        return _message(
          context,
          icon: Icons.info_outline,
          color: colors.muted,
          title: L10n.instance.tr('发现新版本'),
          detail: L10n.instance.tr('未找到适用于当前平台的安装包，可在发布页面手动下载。'),
        );
      case UpdateStatus.available:
        return _available(context, model);
      case UpdateStatus.downloading:
        return _downloading(context, model);
      case UpdateStatus.downloaded:
        return _downloaded(context, model);
      case UpdateStatus.error:
        return _message(
          context,
          icon: Icons.error_outline,
          color: colors.danger,
          title: L10n.instance.tr('检查更新失败'),
          detail: L10n.instance.tr(model.error ?? '请稍后重试'),
        );
    }
  }

  Widget _available(BuildContext context, UpdateViewModel model) {
    final colors = appColors(context);
    final result = model.result!;
    final release = result.release;
    final asset = result.asset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          trf('发现新版本 %s', [release.tagName.isEmpty ? result.remoteVersion.toString() : release.tagName]),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _line(context, L10n.instance.tr('当前版本'), result.localVersion.toString()),
        _line(context, L10n.instance.tr('最新版本'), result.remoteVersion.toString()),
        _line(context, L10n.instance.tr('平台'), _platformLabel(result.platform)),
        if (release.publishedAt != null)
          _line(context, L10n.instance.tr('发布日期'), _formatDate(release.publishedAt!)),
        if (asset != null) ...[
          _line(context, L10n.instance.tr('安装包'), asset.name),
          if (asset.hasSize)
            _line(context, L10n.instance.tr('安装包大小'), humanSize(asset.size)),
        ],
        const SizedBox(height: 10),
        Text(
          L10n.instance.tr('更新说明'),
          style: TextStyle(fontWeight: FontWeight.w600, color: colors.muted),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: SelectableText(
            release.notes.trim().isEmpty
                ? L10n.instance.tr('暂无更新说明')
                : release.notes.trim(),
            style: TextStyle(fontSize: 12.5, height: 1.45, color: colors.text),
          ),
        ),
      ],
    );
  }

  Widget _downloading(BuildContext context, UpdateViewModel model) {
    final colors = appColors(context);
    final percent = model.total > 0 ? '${(model.progress * 100).round()}%' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          L10n.instance.tr('正在下载安装包…'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: model.total > 0 ? model.progress : null,
          color: colors.accent,
          backgroundColor: colors.border,
        ),
        const SizedBox(height: 8),
        Text(
          model.total > 0
              ? '${humanSize(model.received)} / ${humanSize(model.total)}  $percent'
              : humanSize(model.received),
          style: TextStyle(fontSize: 12, color: colors.muted),
        ),
      ],
    );
  }

  Widget _downloaded(BuildContext context, UpdateViewModel model) {
    final colors = appColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _message(
          context,
          icon: Icons.download_done,
          color: colors.accent,
          title: L10n.instance.tr('下载完成'),
          detail: L10n.instance.tr('安装包已保存，可以直接打开或分享。'),
        ),
        const SizedBox(height: 8),
        SelectableText(
          model.downloadedFile?.path ?? '',
          style: TextStyle(fontSize: 11.5, color: colors.muted),
        ),
      ],
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
  }) {
    final colors = appColors(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(fontSize: 12.5, height: 1.45, color: colors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final colors = appColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colors.muted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, UpdateViewModel model) {
    final platform = model.result?.platform ?? model.platform;
    final actions = <Widget>[];
    switch (model.status) {
      case UpdateStatus.idle:
        actions.add(TextButton(
          onPressed: () => model.check(),
          child: Text(L10n.instance.tr('检查更新')),
        ));
      case UpdateStatus.checking:
        actions.add(TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L10n.instance.tr('隐藏')),
        ));
      case UpdateStatus.upToDate:
        actions.add(TextButton(
          onPressed: () => model.check(localVersion: model.localVersion),
          child: Text(L10n.instance.tr('重新检查')),
        ));
      case UpdateStatus.available:
        actions.add(TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L10n.instance.tr('稍后')),
        ));
        actions.add(TextButton(
          onPressed: () async {
            final ok = await model.copyLink();
            if (context.mounted) {
              showAppSnack(
                context,
                L10n.instance.tr(ok ? '已复制下载链接' : '没有可用的下载链接'),
              );
            }
          },
          child: Text(L10n.instance.tr('复制链接')),
        ));
        actions.add(TextButton(
          onPressed: () => _openBrowser(context, model),
          child: Text(L10n.instance.tr('在浏览器中打开')),
        ));
        actions.add(FilledButton(
          onPressed: model.download,
          child: Text(_downloadLabel(platform)),
        ));
      case UpdateStatus.noAsset:
        actions.add(TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L10n.instance.tr('关闭')),
        ));
        actions.add(FilledButton(
          onPressed: () => _openBrowser(context, model),
          child: Text(L10n.instance.tr('在浏览器中打开')),
        ));
      case UpdateStatus.downloading:
        actions.add(TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L10n.instance.tr('隐藏')),
        ));
      case UpdateStatus.downloaded:
        actions.add(TextButton(
          onPressed: () => _openBrowser(context, model),
          child: Text(L10n.instance.tr('在浏览器中打开')),
        ));
        actions.add(TextButton(
          onPressed: () async {
            final ok = await model.copyLink();
            if (context.mounted) {
              showAppSnack(
                context,
                L10n.instance.tr(ok ? '已复制下载链接' : '没有可用的下载链接'),
              );
            }
          },
          child: Text(L10n.instance.tr('复制链接')),
        ));
        actions.add(FilledButton(
          onPressed: () async {
            final error = await model.openDownloaded();
            if (context.mounted && error != null) {
              showAppSnack(context, L10n.instance.tr(error));
            }
          },
          child: Text(L10n.instance.tr(
            platform == UpdatePlatform.ios ? '分享安装包' : '打开安装包',
          )),
        ));
      case UpdateStatus.error:
        final retryDownload = model.result?.asset != null;
        actions.add(TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L10n.instance.tr('关闭')),
        ));
        actions.add(FilledButton(
          onPressed: retryDownload
              ? model.download
              : () => model.check(localVersion: model.localVersion),
          child: Text(L10n.instance.tr(retryDownload ? '重试下载' : '重试')),
        ));
    }
    return actions;
  }

  Future<void> _openBrowser(BuildContext context, UpdateViewModel model) async {
    final error = await model.openInBrowser();
    if (context.mounted && error != null) {
      showAppSnack(context, L10n.instance.tr(error));
    }
  }

  static String _downloadLabel(UpdatePlatform platform) {
    return switch (platform) {
      UpdatePlatform.android => L10n.instance.tr('下载 APK'),
      UpdatePlatform.ios => L10n.instance.tr('下载并分享'),
      UpdatePlatform.macOS ||
      UpdatePlatform.windows ||
      UpdatePlatform.linux =>
        L10n.instance.tr('下载安装包'),
    };
  }

  static String _platformLabel(UpdatePlatform platform) {
    return switch (platform) {
      UpdatePlatform.android => 'Android',
      UpdatePlatform.ios => 'iOS',
      UpdatePlatform.macOS => 'macOS',
      UpdatePlatform.windows => 'Windows',
      UpdatePlatform.linux => 'Linux',
    };
  }

  static String _formatDate(DateTime value) {
    final date = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
