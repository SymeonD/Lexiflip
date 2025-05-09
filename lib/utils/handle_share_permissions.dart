import 'package:cards/utils/show_custom_snackbar.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> handleShare(context) async {
  // Request all the necessary permissions at once
  final permissions = [
    Permission.location,
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.nearbyWifiDevices,
  ];

  final statuses = await permissions.request();

  // Check for any denied permissions and show custom snackbar
  final deniedPermissions = statuses.entries
      .where((entry) => !entry.value.isGranted)
      .map((entry) => entry.key)
      .toList();

  if (deniedPermissions.isNotEmpty) {
    // Show the denied permissions to the user
    showCustomSnackBar(
      context,
      "These permissions are required to share the deck: ${deniedPermissions.join(', ')}",
      2,
    );
    return;
  }

  // Proceed with sharing if all permissions are granted
  // Start advertising or other operations here
  // Your advertising logic goes here
}
