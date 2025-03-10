import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Sheet {
  static const double paddingHorizontal = 10;
  static const double paddingVertical = 20;

  static Future<T?> showBottomSheet<T>(BuildContext context, Widget w, {double? rate, GestureTapCallback? onTapBlack}) {
    final Size screenSize = MediaQuery.of(context).size;
    rate ??= 2 / 3;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min, // Prevents unnecessary expansion
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
                height: screenSize.height * (1 - rate!),
                color: Colors.transparent,
              ),
            ),
            Container(
              width: screenSize.width,
              height: screenSize.height * rate,
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

  static Future<T?> withHeaderAndBody<T>(BuildContext context, List<Widget> headerInColumn, Widget body, {double? rate, GestureTapCallback? onTapBlack}) {
    rate ??= 2 / 3;
    final GlobalKey topColumn = GlobalKey();
    return showBottomSheet<T>(
      context,
      Column(children: [
        Column(key: topColumn, children: headerInColumn),
        SheetBody(topColumn, rate, body),
      ]),
      rate: rate,
      onTapBlack: onTapBlack,
    );
  }
}

class SheetBody extends StatefulWidget {
  final GlobalKey topColumn;
  final double rate;
  final Widget child;

  const SheetBody(
    this.topColumn,
    this.rate,
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
    var screenSize = MediaQuery.of(context).size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = widget.topColumn.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final height = screenSize.height * widget.rate - renderBox.size.height - Sheet.paddingVertical * 2;
        if (height != viewHeight) {
          setState(() {
            viewHeight = height;
          });
        }
      }
    });
    return SizedBox(
      width: screenSize.width,
      height: viewHeight,
      child: widget.child,
    );
  }
}
