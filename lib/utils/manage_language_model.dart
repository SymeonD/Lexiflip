import 'dart:async';
import 'dart:isolate';

import 'package:cards/main.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// ignore: constant_identifier_names
enum ManageLanguageModelAction { DOWNLOAD, DELETE }

void manageLanguageModel(
    String languageCode, ManageLanguageModelAction action) async {
  final receivePort = ReceivePort();
  final rootIsolateToken = RootIsolateToken.instance!;

  Isolate? isolate;

  receivePort.listen((message) {
    // Close Snackbar when download is completed
    scaffoldMessengerKey.currentState?.clearSnackBars();
    // Show "Download Complete" for 500ms
    showCustomSnackBar(
      ManageLanguageModelAction.DOWNLOAD == action
          ? "Language downloaded ✅"
          : "Language deleted ✅",
      1,
    );
    receivePort.close(); // Close the receive port after receiving the message
    isolate?.kill(priority: Isolate.immediate); // Kill the isolate
  });

  switch (action) {
    case ManageLanguageModelAction.DOWNLOAD:
      showPersistentSnackbar("Downloading $languageCode language...");
      isolate = await Isolate.spawn(downloadLanguageModel, {
        'sendPort': receivePort.sendPort,
        'languageCode': languageCode,
        'rootIsolateToken': rootIsolateToken,
      });
      break;

    case ManageLanguageModelAction.DELETE:
      showPersistentSnackbar("Deleting $languageCode language...");
      isolate = await Isolate.spawn(deleteLanguageModel, {
        'sendPort': receivePort.sendPort,
        'languageCode': languageCode,
        'rootIsolateToken': rootIsolateToken,
      });
      break;
  }
}

void showPersistentSnackbar(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(days: 1), // Make it persist until dismissed
    action: SnackBarAction(
      label: "Dismiss",
      onPressed: () {
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      },
    ),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(
      bottom: 20, // Adjust to control height from bottom
      left: 20, // 5% margin on left
      right: 20, // 5% margin on right
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Rounded corners
    ),
  ));
}

void downloadLanguageModel(Map<String, dynamic> args) async {
  SendPort sendPort = args['sendPort'];
  String languageCode = args['languageCode'];
  RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    final languageModelManager = OnDeviceTranslatorModelManager();
    await languageModelManager.downloadModel(languageCode,
        isWifiRequired: false);
    sendPort.send("Download Completed for $languageCode");
  } catch (e) {
    sendPort.send("Download Failed: $e");
  } finally {
    Isolate.exit(); // Ensure the isolate exits after completion
  }
}

Future<void> deleteLanguageModel(Map<String, dynamic> args) async {
  SendPort sendPort = args['sendPort'];
  String languageCode = args['languageCode'];
  RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    final languageModelManager = OnDeviceTranslatorModelManager();
    await languageModelManager.deleteModel(languageCode);
    sendPort.send("Deletion Completed for $languageCode");
  } catch (e) {
    sendPort.send("Deletion Failed: $e");
  } finally {
    Isolate.exit(); // Ensure the isolate exits after completion
  }
}
