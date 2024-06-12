import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot_callback/screenshot_callback.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  final _receivePort = ReceivePort();
  SendPort? homePort;
  String? latestMessageFromOverlay;
  ScreenshotCallback screenshotCallback = ScreenshotCallback();
  File? _firstImage;

  @override
  void initState() {
    super.initState();
    // screenshotCallback.dispose();

    // Screenshot callback listener
    screenshotCallback.addListener(() async {
      log('HomePage Listener called');

      homePort ??= IsolateNameServer.lookupPortByName(_kPortNameOverlay);
      homePort?.send('screen_shot_detected');
      _getFirstImageFromScreenshotFolder();
    });

    // Register the receive port if not already registered
    if (homePort == null) {
      final res = IsolateNameServer.registerPortWithName(
        _receivePort.sendPort,
        _kPortNameHome,
      );
      log("Port registration result: $res");
    }

    _receivePort.listen((message) {
      log("Message from OVERLAY: $message");
      // setState(() {
      //   latestMessageFromOverlay = 'Latest Message From Overlay: $message';
      // });
    });
  }

  Future<void> _getFirstImageFromScreenshotFolder() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String screenshotsPath =
          '${directory.path.split('Android')[0]}DCIM/Screenshots';
      Directory screenshotsDir = Directory(screenshotsPath);

      if (await screenshotsDir.exists()) {
        List<FileSystemEntity> files = screenshotsDir.listSync();
        files.sort((a, b) {
          // Get the last modified time of files a and b
          var aModified = a.statSync().modified;
          var bModified = b.statSync().modified;

          // Compare the last modified times in descending order
          return bModified.compareTo(aModified);
        });
        files = files.where((file) {
          String filePath = file.path;
          return !filePath.contains('.trashed');
        }).toList();

        for (int i = 0; i < files.length; i++) {
          print("File link is ${(files[i] as File).path}");
        }

        print("File is ${files.length}");
        var imageFileIs = files.firstOrNull;
        print("First Image $imageFileIs");

        if (imageFileIs is File && _isImageFile(imageFileIs.path)) {
          setState(() {
            latestMessageFromOverlay = imageFileIs.path;
            _firstImage = imageFileIs;
          });
        }
      }
    }
  }

  bool _isImageFile(String path) {
    final mimeType = lookupMimeType(path);
    return mimeType != null && mimeType.startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Shot'),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TextButton(
            //   onPressed: () async {
            //     final status = await FlutterOverlayWindow.isPermissionGranted();
            //     log("Is Permission Granted: $status");
            //   },
            //   child: const Text("Check Permission"),
            // ),
            // const SizedBox(height: 10.0),
            // TextButton(
            //   onPressed: () async {
            //     final bool? res = await FlutterOverlayWindow.requestPermission();
            //     log("Permission status: $res");
            //   },
            //   child: const Text("Request Permission"),
            // ),
            // const SizedBox(height: 10.0),
            TextButton(
              onPressed: () async {
                if (await FlutterOverlayWindow.isActive()) return;
                await FlutterOverlayWindow.showOverlay(
                  enableDrag: true,
                  overlayTitle: "X-SLAYER",
                  overlayContent: 'Overlay Enabled',
                  flag: OverlayFlag.defaultFlag,
                  visibility: NotificationVisibility.visibilityPublic,
                  alignment: OverlayAlignment.centerRight,
                  height: 80,
                  width: 80,
                );
              },
              child: const Text("Enable Service"),
            ),
            const SizedBox(height: 10.0),
            TextButton(
              onPressed: () {
                FlutterOverlayWindow.closeOverlay().then((value) {
                  screenshotCallback.dispose();
                });
              },
              child: const Text("Close Service"),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(latestMessageFromOverlay ?? ''),
            ),
            _firstImage != null
                ? SizedBox(
                    width: 280, height: 280, child: Image.file(_firstImage!))
                : const Text('Take screen shot every where!'),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNullExtension<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
