import 'dart:async';
import 'dart:isolate';

import 'package:cards/main.dart';
import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// ignore: constant_identifier_names
enum ManageCountryModelAction { DOWNLOAD, DELETE }

void manageCountryModel(
    String countryCode, ManageCountryModelAction action) async {
  final receivePort = ReceivePort();
  final rootIsolateToken = RootIsolateToken.instance!;

  Isolate? isolate;

  receivePort.listen((message) {
    // Close Snackbar when download is completed
    scaffoldMessengerKey.currentState?.clearSnackBars();
    // Show "Download Complete" for 500ms
    showCustomSnackBar(
      ManageCountryModelAction.DOWNLOAD == action
          ? "Country downloaded ✅"
          : "Country deleted ✅",
      1,
    );
    receivePort.close(); // Close the receive port after receiving the message
    isolate?.kill(priority: Isolate.immediate); // Kill the isolate
  });

  switch (action) {
    case ManageCountryModelAction.DOWNLOAD:
      showPersistentSnackbar("Downloading $countryCode country...");
      isolate = await Isolate.spawn(downloadCountryModel, {
        'sendPort': receivePort.sendPort,
        'countryCode': countryCode,
        'rootIsolateToken': rootIsolateToken,
      });
      break;

    case ManageCountryModelAction.DELETE:
      showPersistentSnackbar("Deleting $countryCode country...");
      isolate = await Isolate.spawn(deleteCountryModel, {
        'sendPort': receivePort.sendPort,
        'countryCode': countryCode,
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

void downloadCountryModel(Map<String, dynamic> args) async {
  SendPort sendPort = args['sendPort'];
  String countryCode = args['countryCode'];
  RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    final countryModelManager = OnDeviceTranslatorModelManager();
    await countryModelManager.downloadModel(countryCode,
        isWifiRequired: false);
    sendPort.send("Download Completed for $countryCode");
  } catch (e) {
    sendPort.send("Download Failed: $e");
  } finally {
    Isolate.exit(); // Ensure the isolate exits after completion
  }
}

Future<void> deleteCountryModel(Map<String, dynamic> args) async {
  SendPort sendPort = args['sendPort'];
  String countryCode = args['countryCode'];
  RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    final countryModelManager = OnDeviceTranslatorModelManager();
    await countryModelManager.deleteModel(countryCode);
    sendPort.send("Deletion Completed for $countryCode");
  } catch (e) {
    sendPort.send("Deletion Failed: $e");
  } finally {
    Isolate.exit(); // Ensure the isolate exits after completion
  }
}
