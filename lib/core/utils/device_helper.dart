import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelper {
  static Future<Map<String,dynamic>> getDeviceHeaders() async{
    final deviceInfo = DeviceInfoPlugin();

    String deviceName = "Unknown Mobile";
    String deviceType = "mobile";

    try{
      if(Platform.isAndroid){
        final androidInfo = await deviceInfo.androidInfo;

        deviceName = "${androidInfo.manufacturer} ${androidInfo.model}";

        deviceType = "android";
      }else if(Platform.isIOS){
        final iosInfo = await deviceInfo.iosInfo;

        deviceName = iosInfo.name;

        deviceType = 'ios';
      }
    }catch(e){
      deviceName = "Unkown ${Platform.operatingSystem}";
    }
    return{
      'X-Device-Type': deviceType,
      'User-Agent': deviceName,
    };
  }
}