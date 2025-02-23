import 'package:cards/main.dart';
import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context, String message, int duration,
    [String? buttonText, VoidCallback? onButtonPressed]) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Expanded(child: Text(message)),
        if (buttonText != null)
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(0),
            ),
            onPressed: onButtonPressed,
            child: Text(buttonText,
                style: const TextStyle(
                    color: ThemeColors.primaryWhiteFontColor, fontSize: 12)),
          ),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      bottom: 20, // Adjust to control height from bottom
      left: MediaQuery.of(context).size.width * 0.05, // 5% margin on left
      right: MediaQuery.of(context).size.width * 0.05, // 5% margin on right
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Rounded corners
    ),
    duration: Duration(seconds: duration),
    backgroundColor: ThemeColors.primaryColor,
  ));
}
