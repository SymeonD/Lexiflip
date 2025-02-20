import 'dart:isolate';
import 'dart:ui';

import 'package:cards/utils/country_to_language.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';

enum ManageLanguageModelAction { DOWNLOAD, DELETE }

void downloadLanguageModel(Map<String, dynamic> args) async {
  SendPort sendPort = args['sendPort'];
  String languageCode = args['languageCode'];
  RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

  try {
    // Ensure platform channels work inside the isolate
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    final languageModelManager = OnDeviceTranslatorModelManager();
    await languageModelManager.downloadModel(languageCode);

    sendPort.send("Download Completed for $languageCode");
  } catch (e) {
    sendPort.send("Download Failed: $e");
  }
}

void deleteLanguageModel(Map<String, dynamic> args) async {
  SendPort sendPort = args['sendPort'];
  String languageCode = args['languageCode'];
  RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

  try {
    // Ensure platform channels work inside the isolate
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    final languageModelManager = OnDeviceTranslatorModelManager();
    await languageModelManager.deleteModel(languageCode);

    sendPort.send("Deletion Completed for $languageCode");
  } catch (e) {
    sendPort.send("Deletion Failed: $e");
  }
}

void manageLanguageModel(
    String languageCode, ManageLanguageModelAction action) async {
  final receivePort = ReceivePort();
  final rootIsolateToken = RootIsolateToken.instance!;
  Logger().d("Spawning isolate for $languageCode...");

  switch (action) {
    case ManageLanguageModelAction.DOWNLOAD:
      await Isolate.spawn(downloadLanguageModel, {
        'sendPort': receivePort.sendPort,
        'languageCode': languageCode,
        'rootIsolateToken': rootIsolateToken, // Pass the token
      });

    case ManageLanguageModelAction.DELETE:
      await Isolate.spawn(
        deleteLanguageModel,
        {
          'sendPort': receivePort.sendPort,
          'languageCode': languageCode,
          'rootIsolateToken': rootIsolateToken, // Pass the token
        },
      );

    default:
      throw Exception(
        'Invalid action: $action. Expected "download" or "delete".',
      );
  }

  receivePort.listen((message) {
    Logger().d(message);
  });
}
