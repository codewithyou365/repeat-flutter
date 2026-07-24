import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef OnResultCallback = void Function(String content);

void _qrLog(String msg) {
  debugPrint('QRSCAN ${DateTime.now().toIso8601String()} $msg');
}

class QrScan extends StatefulWidget {
  final OnResultCallback onResult;

  const QrScan(this.onResult, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => QrScanState();
}

class QrScanState extends State<QrScan> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  // Guard so a burst of detections doesn't stack multiple result dialogs.
  // Reset by resumeCamera() when the user chooses to keep scanning.
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _qrLog('initState hashCode=$hashCode');
    WidgetsBinding.instance.addObserver(this);
    // Do NOT start() here: the MobileScanner widget auto-starts the controller.
    // Starting manually as well throws MobileScannerException(controllerInitializing).
  }

  void _startCamera() async {
    _qrLog('start call');
    try {
      await controller.start();
      _qrLog('start done');
    } catch (e) {
      _qrLog('start error $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _qrLog('appLifecycle $state');
    switch (state) {
      case AppLifecycleState.resumed:
        _startCamera();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        break;
    }
  }

  void pauseCamera() async {
    _qrLog('pauseCamera call');
    await controller.stop();
    _qrLog('pauseCamera done');
  }

  void resumeCamera() async {
    _qrLog('resumeCamera call');
    _handled = false;
    await controller.start();
    _qrLog('resumeCamera done');
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _qrLog('scanned code=$code');
        _handled = true;
        widget.onResult(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _qrLog('build');
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 150.0 : 300.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) {
            _qrLog('errorBuilder ${error.errorCode} ${error.errorDetails?.message}');
            return Center(
              child: Text(
                error.errorCode.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        ),
        // Simple visual guide replacing the old QrScannerOverlayShape.
        IgnorePointer(
          child: Container(
            width: scanArea,
            height: scanArea,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _qrLog('dispose hashCode=$hashCode');
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }
}
