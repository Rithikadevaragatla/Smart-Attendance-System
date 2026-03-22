import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// Scans BLE advertisements and extracts sessionId
  /// from manufacturer data with ID = 1234
 Future<Map<String, String>?> scanForSession() async {
  Map<String, String>? foundSession;

  await FlutterBluePlus.startScan(
    timeout: const Duration(seconds: 6),
  );

  _scanSub = FlutterBluePlus.scanResults.listen((results) {
    for (ScanResult result in results) {
      final manufacturerData =
          result.advertisementData.manufacturerData;

      if (manufacturerData.containsKey(1234)) {
        final List<int> rawData = manufacturerData[1234]!;
        final data = String.fromCharCodes(rawData);

        // Expected: sessionId|CSE|A
        final parts = data.split("|");

        if (parts.length == 3) {
          foundSession = {
            "sessionId": parts[0],
            "class": parts[1],
            "section": parts[2],
          };
          break;
        }
      }
    }
  });

  await Future.delayed(const Duration(seconds: 6));

  await FlutterBluePlus.stopScan();
  await _scanSub?.cancel();

  return foundSession;
}
}
