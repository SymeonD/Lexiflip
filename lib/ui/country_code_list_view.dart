import 'dart:isolate';

import 'package:canopas_country_picker/canopas_country_picker.dart';
import 'package:cards/utils/country_to_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:logger/logger.dart';

class CountryCodeListView extends StatelessWidget {
  final List<CountryCode> codes;
  final ScrollController? controller;

  const CountryCodeListView(
      {super.key, required this.codes, required this.controller});

  static void downloadLanguageModel(Map<String, dynamic> args) async {
    SendPort sendPort = args['sendPort'];
    String languageCode = args['languageCode'];
    RootIsolateToken rootIsolateToken = args['rootIsolateToken'];

    try {
      // Ensure platform channels work inside the isolate
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

      final languageModelManager = OnDeviceTranslatorModelManager();
      await languageModelManager.downloadModel(getLanguageCode(languageCode)!);

      sendPort.send("Download Completed for $languageCode");
    } catch (e) {
      sendPort.send("Download Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: codes.length,
      itemBuilder: (context, index) {
        final code = codes[index];
        return ListTile(
          title: Text(code.name),
          leading: Text(code.flag, style: const TextStyle(fontSize: 24)),
          onTap: () async {
            final receivePort = ReceivePort();
            final rootIsolateToken = RootIsolateToken.instance!;
            Logger().d("Spawning isolate for ${code.code}...");

            await Isolate.spawn(
              downloadLanguageModel,
              {
                'sendPort': receivePort.sendPort,
                'languageCode': code.code,
                'rootIsolateToken': rootIsolateToken, // Pass the token
              },
            );

            receivePort.listen((message) {
              Logger().d(message);
            });
            context.mounted ? Navigator.pop(context, code) : null;
          },
        );
      },
    );
  }
}
