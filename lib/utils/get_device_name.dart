import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.manufacturer} ${androidInfo.model}"; // ex: "samsung SM-G991B"
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name; // ex: "iPhone de Julie" (sur iOS, .name EST le nom personnalisé !)
    }
    
    return "Unknown device";
  }