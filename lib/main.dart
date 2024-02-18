import 'package:charged/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './app.dart';
import './service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkPermissions();
  await initializeService();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(ChargeApp(prefs: prefs));
}
