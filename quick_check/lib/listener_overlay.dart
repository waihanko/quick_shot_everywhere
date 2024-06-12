import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:bg_launcher/bg_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:screenshot_callback/screenshot_callback.dart';

class ListenerOverlay extends StatefulWidget {
  const ListenerOverlay({Key? key}) : super(key: key);

  @override
  State<ListenerOverlay> createState() => _ListenerOverlayState();
}

class _ListenerOverlayState extends State<ListenerOverlay> {
  final _receivePort = ReceivePort();
  SendPort? homePort;
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  ScreenshotCallback screenshotCallback = ScreenshotCallback();

  void bringAppToForeground() {
    Future.delayed(
      const Duration(seconds: 1),
      () => BgLauncher.bringAppToForeground(
        action: 'android.intent.action.MAIN',
        extras: "com.example.quick_check",
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (homePort != null) return;
    final res = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _kPortNameOverlay,
    );
    log("$res : HOME");
    _receivePort.listen((message) {
      if (message == "screen_shot_detected") {
        log("Taking screen shot");
        bringAppToForeground();
      }
      log("message from UI: $message");
      // setState(() {
      //   messageFromOverlay = 'message from UI: $message';
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        homePort ??= IsolateNameServer.lookupPortByName(
          _kPortNameHome,
        );
        homePort?.send('Date: ${DateTime.now()}');
      },
      child: BlinkingRecorderIcon(),
    );
  }
}

class BlinkingRecorderIcon extends StatefulWidget {
  @override
  _BlinkingRecorderIconState createState() => _BlinkingRecorderIconState();
}

class _BlinkingRecorderIconState extends State<BlinkingRecorderIcon> {
  bool _isVisible = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _isVisible = !_isVisible;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.5), shape: BoxShape.circle),
      child: Icon(
        Icons.fiber_manual_record,
        color: _isVisible ? Colors.red[300] : Colors.red,
        size: 20,
        // opacity: _isVisible ? 1.0 : 0.0, // Set opacity based on visibility
      ),
    );
  }
}
