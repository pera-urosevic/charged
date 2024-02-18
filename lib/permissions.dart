import 'package:charged/log.dart';
import 'package:permission_handler/permission_handler.dart';

checkPermissions() async {
  final PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    log('Notification permission granted');
  } else if (status.isDenied) {
    await openAppSettings();
  } else if (status.isPermanentlyDenied) {
    await openAppSettings();
  }
}
