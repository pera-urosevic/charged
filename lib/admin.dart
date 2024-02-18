import 'dart:async';

import 'package:charged/defaults.dart';
import 'package:charged/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  final SharedPreferences prefs;
  const AdminPage({super.key, required this.prefs});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  double _lowBattery = defaultLowBattery.toDouble();
  double _highBattery = defaultHighBattery.toDouble();

  @override
  void initState() {
    super.initState();
    _lowBattery = widget.prefs.getInt('lowBattery')?.toDouble() ?? _lowBattery;
    _highBattery = widget.prefs.getInt('highBattery')?.toDouble() ?? _highBattery;
    Timer(const Duration(seconds: 10), () {
      FlutterBackgroundService().invoke('check status');
    });
  }

  @override
  Widget build(BuildContext context) {
    String labelLowBattery = '${_lowBattery.toInt()}%';
    String labelHighBattery = '${_highBattery.toInt()}%';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Charge Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Low Battery: $labelLowBattery'),
            Slider(
              min: minLowBattery.toDouble(),
              max: maxLowBattery.toDouble(),
              divisions: (maxLowBattery - minLowBattery) ~/ 5,
              value: _lowBattery,
              onChanged: (value) {
                setState(() {
                  _lowBattery = value;
                });
              },
              onChangeEnd: (value) {
                int newLowBattery = value.toInt();
                widget.prefs.setInt('lowBattery', newLowBattery);
                FlutterBackgroundService().invoke('configuration changed', {'lowBattery': newLowBattery});
              },
            ),
            const SizedBox(height: 12.0),
            Text('High Battery: $labelHighBattery'),
            Slider(
              min: minHighBattery.toDouble(),
              max: maxHighBattery.toDouble(),
              divisions: (maxHighBattery - minHighBattery) ~/ 5,
              value: _highBattery,
              onChanged: (value) {
                setState(() {
                  _highBattery = value;
                });
              },
              onChangeEnd: (value) {
                int newHighBattery = value.toInt();
                widget.prefs.setInt('highBattery', newHighBattery);
                FlutterBackgroundService().invoke('configuration changed', {'highBattery': newHighBattery});
              },
            ),
            const SizedBox(height: 24.0),
            StreamBuilder<Map<String, dynamic>?>(
              stream: FlutterBackgroundService().on('status update'),
              builder: (context, snapshot) {
                log('admin on status update ${snapshot.data}');
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data!;
                final now = data['now'] != null ? '${data['now']}\n' : '';
                final state = data['state'] != null ? '${data['state']} ' : '??? ';
                final level = data['level'] != null ? '${data['level']}%' : '??%';
                return Text('$now$state$level', textAlign: TextAlign.center);
              },
            ),
          ],
        ),
      ),
    );
  }
}
