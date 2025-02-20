import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';

void showNetworkSettingsPrompt(
    BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            AppSettings.openAppSettings(); // Open app settings
            Navigator.pop(context);
          },
          child: const Text("Open Settings"),
        ),
      ],
    ),
  );
}
