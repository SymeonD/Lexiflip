import 'package:flutter/material.dart';

// Show a custom dialog with a message and a loading indicator
// When the prompt is closed, it will return a boolean value
void showSharePrompt(BuildContext context, String message, bool loading) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            Expanded(child: Text(message)),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
