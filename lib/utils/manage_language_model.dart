import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';

enum ManageLanguageModelAction { DOWNLOAD, DELETE }

void manageLanguageModel(
    String languageCode, ManageLanguageModelAction action) async {
  final receivePort = ReceivePort();
  final rootIsolateToken = RootIsolateToken.instance!;
  Logger().d("Spawning isolate for $languageCode...");

  Isolate? isolate;

  receivePort.listen((message) {
    Logger().d(message);
    receivePort.close(); // Close the receive port after receiving the message
    isolate?.kill(priority: Isolate.immediate); // Kill the isolate
  });

  switch (action) {
    case ManageLanguageModelAction.DOWNLOAD:
      isolate = await Isolate.spawn(downloadLanguageModel, {
        'sendPort': receivePort.sendPort,
        'languageCode': languageCode,
        'rootIsolateToken': rootIsolateToken,
      });
      break;

    case ManageLanguageModelAction.DELETE:
      isolate = await Isolate.spawn(deleteLanguageModel, {
        'sendPort': receivePort.sendPort,
        'languageCode': languageCode,
        'rootIsolateToken': rootIsolateToken,
      });
      break;
  }
}

void downloadLanguageModel(Map<String, dynamic> args) async {
  SendPort sendPort = args['sendPort'];
  String languageCode = args['languageCode'];
  RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    final languageModelManager = OnDeviceTranslatorModelManager();
    await languageModelManager.downloadModel(languageCode);
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
