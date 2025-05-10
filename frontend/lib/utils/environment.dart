import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<bool> isRunningOnEmulator() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return !androidInfo.isPhysicalDevice;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return !iosInfo.isPhysicalDevice;
  } else {
    return false;
  }
}
