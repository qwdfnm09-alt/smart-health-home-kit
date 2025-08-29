import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// طلب إذن البلوتوث
  static Future<bool> requestBluetoothPermission() async {
    var status = await Permission.bluetoothScan.request();
    if (status.isGranted) {
      return true;
    }
    return false;
  }

  /// طلب إذن الموقع (مهم لبعض أجهزة BLE)
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      return true;
    }
    return false;
  }

  /// طلب كل الصلاحيات مع بعض
  static Future<bool> requestAllPermissions() async {
    var statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }
}

