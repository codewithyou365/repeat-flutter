import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/i18n/i18n_translations.dart';
import 'package:repeat_flutter/widget/gesture/pinch_viewer.dart';

const double boxSize = 200;
const Offset center = Offset(boxSize / 2, boxSize / 2);

/// 跟 PinchViewer.build 里那个 Transform 等价的正向映射：
/// 内容坐标 p -> 屏幕坐标。用来验"手指底下那个点没跑"。
Offset forward(Offset p, {required double scale, required double rotation, required Offset offset}) {
  return offset + rotateScale(p - center, rotation, scale) + center;
}

/// [forward] 的逆映射：屏幕坐标 -> 内容坐标。
Offset inverse(Offset s, {required double scale, required double rotation, required Offset offset}) {
  return center + rotateScale(s - offset - center, -rotation, 1 / scale);
}

void expectOffsetCloseTo(Offset actual, Offset expected, [double epsilon = 1e-9]) {
  expect(actual.dx, closeTo(expected.dx, epsilon));
  expect(actual.dy, closeTo(expected.dy, epsilon));
}

/// 从任意起始状态出发做一次手势，验证锚点不变量。
void expectAnchorHeld({
  required double startScale,
  required double startRotation,
  required Offset startOffset,
  required Offset startFocal,
  required Offset focal,
  required double gestureScale,
  required double gestureRotation,
  double minScale = 1,
  double maxScale = 6,
}) {
  final anchor = inverse(startFocal, scale: startScale, rotation: startRotation, offset: startOffset);
  final next = computePinch(
    startScale: startScale,
    startRotation: startRotation,
    startOffset: startOffset,
    startFocal: startFocal,
    focal: focal,
    center: center,
    gestureScale: gestureScale,
    gestureRotation: gestureRotation,
    minScale: minScale,
    maxScale: maxScale,
  );
  expectOffsetCloseTo(
    forward(anchor, scale: next.scale, rotation: next.rotation, offset: next.offset),
    focal,
    1e-6,
  );
}

Future<void> pumpViewer(
  WidgetTester tester, {
  GlobalKey<PinchViewerState>? key,
  VoidCallback? onTap,
}) async {
  // 用 GetMaterialApp + 真的翻译表："还原"按钮上的文案走 .tr，
  // 没挂翻译表的话会退化成显示 key 本身，那串长度不真实。
  await tester.pumpWidget(
    GetMaterialApp(
      translations: I18nTranslations(),
      locale: I18nLocal.zh.locale,
      fallbackLocale: I18nLocal.en.locale,
      home: Center(
        child: SizedBox(
          width: boxSize,
          height: boxSize,
          child: PinchViewer(
            key: key,
            onTap: onTap,
            child: Container(color: const Color(0xFF000000)),
          ),
        ),
      ),
    ),
  );
}

Matrix4 transformOf(WidgetTester tester) {
  final t = tester.widget<Transform>(
    find.descendant(of: find.byType(PinchViewer), matching: find.byType(Transform)).first,
  );
  return t.transform;
}

double scaleOf(Matrix4 m) {
  // 矩阵左上角是 R(rot)·S(scale)，第一列的模长就是 scale。
  return math.sqrt(m.storage[0] * m.storage[0] + m.storage[1] * m.storage[1]);
}

double rotationOf(Matrix4 m) => math.atan2(m.storage[1], m.storage[0]);

Offset translationOf(Matrix4 m) => Offset(m.storage[12], m.storage[13]);

/// 双击留下的 300ms 计时器，不走完测试结束时会报 "A Timer is still pending"。
Future<void> settleDoubleTap(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('computePinch 的锚点不变量', () {
    test('原始状态下双指放大：按住的那个点不动', () {
      expectAnchorHeld(
        startScale: 1,
        startRotation: 0,
        startOffset: Offset.zero,
        startFocal: const Offset(60, 60),
        focal: const Offset(60, 60),
        gestureScale: 3,
        gestureRotation: 0,
      );
    });

    test('放大的同时焦点也在移动', () {
      expectAnchorHeld(
        startScale: 1,
        startRotation: 0,
        startOffset: Offset.zero,
        startFocal: const Offset(40, 150),
        focal: const Offset(120, 70),
        gestureScale: 2.5,
        gestureRotation: 0,
      );
    });

    test('旋转也一样，转的时候按住的点不跑', () {
      expectAnchorHeld(
        startScale: 1,
        startRotation: 0,
        startOffset: Offset.zero,
        startFocal: const Offset(30, 80),
        focal: const Offset(30, 80),
        gestureScale: 1,
        gestureRotation: math.pi / 3,
      );
    });

    test('从"已经缩放旋转位移过"的状态接着做手势', () {
      expectAnchorHeld(
        startScale: 2.4,
        startRotation: -0.7,
        startOffset: const Offset(-33, 21),
        startFocal: const Offset(155, 40),
        focal: const Offset(70, 130),
        gestureScale: 1.8,
        gestureRotation: 0.45,
      );
    });

    test('撞到缩放上限之后，按住的点依然不跑', () {
      // 手指还在张开（gestureScale 10），但 scale 被夹在 6。
      // 增量若不按夹过的结果反算，画面就会跟着手指一路漂走。
      expectAnchorHeld(
        startScale: 3,
        startRotation: 0.2,
        startOffset: const Offset(12, -8),
        startFocal: const Offset(140, 60),
        focal: const Offset(140, 60),
        gestureScale: 10,
        gestureRotation: 0,
        maxScale: 6,
      );
    });

    test('撞到缩放下限之后同理', () {
      expectAnchorHeld(
        startScale: 1.2,
        startRotation: 0,
        startOffset: const Offset(5, 5),
        startFocal: const Offset(80, 80),
        focal: const Offset(80, 80),
        gestureScale: 0.1,
        gestureRotation: 0,
        minScale: 1,
      );
    });
  });

  group('computePinch 的上下限和旋转累计', () {
    PinchState run({
      double startScale = 1,
      double startRotation = 0,
      double gestureScale = 1,
      double gestureRotation = 0,
      double minScale = 1,
      double maxScale = 6,
    }) {
      return computePinch(
        startScale: startScale,
        startRotation: startRotation,
        startOffset: Offset.zero,
        startFocal: center,
        focal: center,
        center: center,
        gestureScale: gestureScale,
        gestureRotation: gestureRotation,
        minScale: minScale,
        maxScale: maxScale,
      );
    }

    test('缩放夹在 [minScale, maxScale]', () {
      expect(run(gestureScale: 100).scale, 6);
      expect(run(gestureScale: 0.001).scale, 1);
      expect(run(startScale: 2, gestureScale: 1.5).scale, closeTo(3, 1e-9));
    });

    test('旋转是累计的，不夹', () {
      expect(run(startRotation: 1, gestureRotation: 0.5).rotation, closeTo(1.5, 1e-9));
      expect(run(startRotation: -1, gestureRotation: -3).rotation, closeTo(-4, 1e-9));
    });
  });

  group('PinchViewer 的接线', () {
    testWidgets('没放大时单指拖不动', (tester) async {
      await pumpViewer(tester);
      await tester.drag(find.byType(PinchViewer), const Offset(40, 40));
      await tester.pump();
      expect(translationOf(transformOf(tester)), Offset.zero);
      expect(scaleOf(transformOf(tester)), closeTo(1, 1e-9));
      await settleDoubleTap(tester);
    });

    testWidgets('双指捏合能放大，双击复位', (tester) async {
      await pumpViewer(tester);
      final c = tester.getCenter(find.byType(PinchViewer));
      final p1 = await tester.startGesture(c + const Offset(-10, 0), pointer: 1);
      final p2 = await tester.startGesture(c + const Offset(10, 0), pointer: 2);
      await p1.moveTo(c + const Offset(-60, 0));
      await p2.moveTo(c + const Offset(60, 0));
      await tester.pump();
      await p1.up();
      await p2.up();
      await tester.pump();
      expect(scaleOf(transformOf(tester)), greaterThan(1.5));

      await tester.tap(find.byType(PinchViewer));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(PinchViewer));
      await tester.pump();
      expect(scaleOf(transformOf(tester)), closeTo(1, 1e-9));
      expect(translationOf(transformOf(tester)), Offset.zero);
      await settleDoubleTap(tester);
    });

    testWidgets('放大之后单指才能拖', (tester) async {
      await pumpViewer(tester);
      final c = tester.getCenter(find.byType(PinchViewer));
      final p1 = await tester.startGesture(c + const Offset(-20, 0), pointer: 1);
      final p2 = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
      await p1.moveTo(c + const Offset(-60, 0));
      await p2.moveTo(c + const Offset(60, 0));
      await tester.pump();
      await p1.up();
      await p2.up();
      await tester.pump();
      // 只做定性断言：手势识别器的缩放基线是在"第一根手指开始动"那一刻取的，
      // 精确到小数点的倍数由上面 computePinch 那组纯函数测试负责。
      expect(scaleOf(transformOf(tester)), greaterThan(1.2));

      final before = translationOf(transformOf(tester));
      await tester.drag(find.byType(PinchViewer), const Offset(80, 0));
      await tester.pump();
      // WidgetTester.drag 会先把 kDragSlopDefault(20) 走掉再发真正的位移，
      // 手势识别器的基线取在那之后，所以画面只跟着动 80 - 20。
      expect(translationOf(transformOf(tester)).dx - before.dx, closeTo(60, 1));
      await settleDoubleTap(tester);
    });

    testWidgets('单击照样透传给底下的逻辑', (tester) async {
      var tapped = 0;
      await pumpViewer(tester, onTap: () => tapped++);
      await tester.tap(find.byType(PinchViewer));
      await settleDoubleTap(tester);
      expect(tapped, 1);
    });

    testWidgets('画面不在原位才出"还原"按钮，点它就复位', (tester) async {
      await pumpViewer(tester);
      final restore = find.byIcon(Icons.restart_alt);
      expect(restore, findsNothing);

      final c = tester.getCenter(find.byType(PinchViewer));
      final p1 = await tester.startGesture(c + const Offset(-10, 0), pointer: 1);
      final p2 = await tester.startGesture(c + const Offset(10, 0), pointer: 2);
      await p1.moveTo(c + const Offset(-60, 0));
      await p2.moveTo(c + const Offset(60, 0));
      await tester.pump();
      await p1.up();
      await p2.up();
      await tester.pump();
      expect(restore, findsOneWidget);

      await tester.tap(restore);
      await tester.pump();
      expect(scaleOf(transformOf(tester)), closeTo(1, 1e-9));
      expect(translationOf(transformOf(tester)), Offset.zero);
      expect(restore, findsNothing);
      await settleDoubleTap(tester);
    });

    testWidgets('只转过没缩放也算不在原位，按钮照出', (tester) async {
      await pumpViewer(tester);
      final c = tester.getCenter(find.byType(PinchViewer));
      // 两指连线转 90 度，间距不变（缩放仍是 1）。
      final p1 = await tester.startGesture(c + const Offset(-40, 0), pointer: 1);
      final p2 = await tester.startGesture(c + const Offset(40, 0), pointer: 2);
      await p1.moveTo(c + const Offset(0, -40));
      await p2.moveTo(c + const Offset(0, 40));
      await tester.pump();
      await p1.up();
      await p2.up();
      await tester.pump();

      // 只断言"转过了"：具体转了多少受手势识别器基线影响，
      // 精确角度由上面 computePinch 那组纯函数测试负责。
      expect(rotationOf(transformOf(tester)).abs(), greaterThan(0.5));
      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
      await settleDoubleTap(tester);
    });

    testWidgets('reset() 清掉上一条内容留下的缩放', (tester) async {
      final key = GlobalKey<PinchViewerState>();
      await pumpViewer(tester, key: key);
      final c = tester.getCenter(find.byType(PinchViewer));
      final p1 = await tester.startGesture(c + const Offset(-10, 0), pointer: 1);
      final p2 = await tester.startGesture(c + const Offset(10, 0), pointer: 2);
      await p1.moveTo(c + const Offset(-60, 0));
      await p2.moveTo(c + const Offset(60, 0));
      await tester.pump();
      await p1.up();
      await p2.up();
      await tester.pump();
      expect(scaleOf(transformOf(tester)), greaterThan(1.5));

      key.currentState!.reset();
      await tester.pump();
      expect(scaleOf(transformOf(tester)), closeTo(1, 1e-9));
      await settleDoubleTap(tester);
    });
  });
}
