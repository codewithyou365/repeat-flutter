import 'package:flutter/material.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';

/// 「管理订阅」的帮助页：哪个是游戏、哪个是提示服务、提示服务怎么挂到字段上。
///
/// 示意图用真控件画（跟 [GameListPage] 的列表同款图标和分组），不放截图：
/// 截图换语言、换深色模式、改界面都会过时。
class GameListHelpPage extends StatelessWidget {
  const GameListHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(I18nKey.subscriptionHelp.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _toolbar(theme),
                const Divider(height: 1),
                _header(theme, I18nKey.gameSectionGame.tr),
                _tile(Icons.videogame_asset, 'Type', 'service/type.js', '1'),
                const Divider(height: 1),
                _header(theme, I18nKey.gameSectionTip.tr),
                _tile(Icons.tips_and_updates, 'Japanese', 'service/japanese.js', '2'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _section(theme, '1', Icons.videogame_asset, I18nKey.gameSectionGame.tr, I18nKey.subscriptionHelpGame.tr),
          _section(theme, '2', Icons.tips_and_updates, I18nKey.gameSectionTip.tr, I18nKey.subscriptionHelpTip.tr),
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 16),
            child: Text(I18nKey.subscriptionHelpTipSteps.tr, style: theme.textTheme.bodyMedium),
          ),
          _section(theme, '3', Icons.more_vert, '', I18nKey.subscriptionHelpToolbar.tr),
        ],
      ),
    );
  }

  /// 示意图顶部那条：标题 + 右上角三个按钮，按钮那一组标 ③。
  Widget _toolbar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(child: Text(I18nKey.manageSubscription.tr, style: theme.textTheme.titleMedium)),
          const Icon(Icons.refresh, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.add, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.more_vert, size: 20),
          const SizedBox(width: 8),
          _badge(theme, '3'),
        ],
      ),
    );
  }

  static Widget _header(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
    );
  }

  Widget _tile(IconData icon, String name, String service, String badge) {
    return Builder(
      builder: (context) => ListTile(
        dense: true,
        leading: Icon(icon),
        title: Text(name),
        subtitle: Text('$service · ${I18nKey.gameReady.tr}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: _badge(Theme.of(context), badge),
      ),
    );
  }

  static Widget _badge(ThemeData theme, String text) {
    return CircleAvatar(
      radius: 11,
      backgroundColor: theme.colorScheme.error,
      child: Text(text, style: TextStyle(fontSize: 12, color: theme.colorScheme.onError)),
    );
  }

  Widget _section(ThemeData theme, String badge, IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge(theme, badge),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Row(
                    children: [
                      Icon(icon, size: 18),
                      const SizedBox(width: 6),
                      Text(title, style: theme.textTheme.titleSmall),
                    ],
                  ),
                if (title.isNotEmpty) const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
