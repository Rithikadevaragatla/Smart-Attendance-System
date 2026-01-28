import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// Scans BLE advertisements and extracts sessionId
  /// from manufacturer data with ID = 1234
  Future<String?> scanForSessionId() async {
    String? sessionId;

    // Start BLE scan
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 6),
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        final manufacturerData =
            result.advertisementData.manufacturerData;

        if (manufacturerData.containsKey(1234)) {
          final List<int> rawData = manufacturerData[1234]!;
          sessionId = String.fromCharCodes(rawData);
          break;
        }
      }
    });

    // Wait for scan duration
    await Future.delayed(const Duration(seconds: 6));

    // Stop scan
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();

    return sessionId;
  }
}
