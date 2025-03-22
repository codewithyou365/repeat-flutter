import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class Sheet {
  static const double paddingHorizontal = 10;
  static const double paddingVertical = 20;
  static final Logger logger = Logger();

  static Future<T?> showBottomSheet<T>(BuildContext context, Widget w, {double? rate, double? height, GestureTapCallback? onTapBlack}) {
    final Size screenSize = MediaQuery.of(context).size;
    rate ??= 2 / 3;
    height ??= screenSize.height * rate - MediaQuery.of(context).padding.top;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (onTapBlack != null) {
                  onTapBlack();
                } else {
                  Get.back();
                }
              },
              child: Container(
                width: screenSize.width,
                height: screenSize.height - height!,
                color: Colors.transparent,
              ),
            ),
            Container(
              width: screenSize.width,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
                child: w,
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<T?> withHeaderAndBody<T>(BuildContext context, Widget header, Widget body, {double? rate, double? height, GestureTapCallback? onTapBlack}) {
    final Size screenSize = MediaQuery.of(context).size;
    rate ??= 2 / 3;
    height ??= screenSize.height * rate - MediaQuery.of(context).padding.top;
    GlobalKey? headerKey = header.key as GlobalKey<State<StatefulWidget>>?;
    if (headerKey == null) {
      logger.e("Error: header widget must have a GlobalKey");
      headerKey = GlobalKey<State<StatefulWidget>>();
    }
    return showBottomSheet<T>(
      context,
      Column(children: [
        header,
        SheetBody(headerKey, screenSize.width, height, body),
      ]),
      height: height,
      onTapBlack: onTapBlack,
    );
  }
}

class SheetBody extends StatefulWidget {
  final GlobalKey topColumn;
  final double totalWidth;
  final double totalHeight;
  final Widget child;

  const SheetBody(
    this.topColumn,
    this.totalWidth,
    this.totalHeight,
    this.child, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SheetBodyState();
}

class SheetBodyState extends State<SheetBody> {
  double viewHeight = 50;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = widget.topColumn.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final height = widget.totalHeight - renderBox.size.height - Sheet.paddingVertical * 2;
        if (height != viewHeight) {
          setState(() {
            viewHeight = height;
          });
        }
      }
    });
    return SizedBox(
      width: widget.totalWidth,
      height: viewHeight,
      child: widget.child,
    );
  }
}
