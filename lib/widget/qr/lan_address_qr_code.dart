import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/row/row_widget.dart';
import 'package:repeat_flutter/widget/snackbar/snackbar.dart';

/// 直接展示局域网地址的二维码。多个地址时用滚轮选择器切换，
/// 二维码下方显示完整地址，底部提供复制/钥匙(凭据)按钮。
class LanAddressQrCode extends StatefulWidget {
  /// 完整地址（已拼好凭据等后缀），为空时不渲染任何内容。
  final List<String> addresses;

  /// 可选标题，如「原始地址」。
  final String? title;

  /// 可选的标题行右侧控件，如「分享笔记」提示。
  final Widget? trailing;

  /// 钥匙(凭据)按钮，为 null 时不显示。
  final VoidCallback? onKey;

  /// 二维码边长，默认 250.w。
  final double? size;

  const LanAddressQrCode({
    super.key,
    required this.addresses,
    this.title,
    this.trailing,
    this.onKey,
    this.size,
  });

  @override
  State<LanAddressQrCode> createState() => _LanAddressQrCodeState();
}

class _LanAddressQrCodeState extends State<LanAddressQrCode> {
  final ValueNotifier<int> index = ValueNotifier(0);

  @override
  void didUpdateWidget(covariant LanAddressQrCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 地址集合变化（服务开关、切换 SSL、刷新凭据）时回到第一个地址
    if (!listEquals(oldWidget.addresses, widget.addresses)) {
      index.value = 0;
    }
  }

  @override
  void dispose() {
    index.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addresses = widget.addresses;
    if (addresses.isEmpty) {
      return const SizedBox.shrink();
    }
    if (index.value >= addresses.length) {
      index.value = 0;
    }
    final size = widget.size ?? 250.w;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: RowWidget.paddingHorizontal, vertical: RowWidget.paddingVertical),
      child: Column(
        children: [
          if (widget.title != null || widget.trailing != null)
            SizedBox(
              height: RowWidget.rowHeight,
              child: Row(
                children: [
                  if (widget.title != null)
                    Text(
                      widget.title!,
                      style: const TextStyle(fontSize: RowWidget.titleFontSize),
                    ),
                  const Spacer(),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          if (addresses.length > 1)
            // 选择器只在地址集合变化时重建：buildCupertinoPicker 每次 build 都会新建
            // FixedExtentScrollController，跟着下标重建会打断滚动。
            RowWidget.buildCupertinoPicker(
              key: ValueKey(addresses.join(',')),
              title: I18nKey.labelLanAddress.tr,
              options: addresses.map((e) => _host(e)).toList(),
              value: index.value,
              changed: (i) => index.value = i,
              pickWidth: 150.w,
            ),
          ValueListenableBuilder<int>(
            valueListenable: index,
            builder: (_, i, child) {
              final address = addresses[i < addresses.length ? i : 0];
              return Column(
                children: [
                  RowWidget.buildQrCode(address, size),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Text(
                      address,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _softButton(
                          context,
                          icon: Icons.copy_rounded,
                          text: I18nKey.btnCopy.tr,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: address));
                            Snackbar.show(I18nKey.labelQrCodeContentCopiedToClipboard.tr);
                          },
                        ),
                      ),
                      if (widget.onKey != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _softButton(
                            context,
                            icon: Icons.vpn_key_rounded,
                            text: I18nKey.keyTitle.tr,
                            onTap: widget.onKey!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 底部浅灰色圆角按钮，深浅色主题都跟随 secondaryHeaderColor。
  Widget _softButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(10);
    return Material(
      color: Theme.of(context).secondaryHeaderColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _host(String address) {
    final host = Uri.tryParse(address)?.host ?? '';
    return host.isEmpty ? address : host;
  }
}
