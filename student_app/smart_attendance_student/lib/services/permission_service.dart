import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestBlePermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
}
