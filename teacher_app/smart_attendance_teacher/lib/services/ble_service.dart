import 'dart:typed_data';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter/foundation.dart';

class BleService {
  static final FlutterBlePeripheral _ble = FlutterBlePeripheral();

  static Future<void> startAdvertising(String sessionId) async {
    debugPrint("🔵 BLE STARTED");
    debugPrint("Broadcasting sessionId: $sessionId");

    await _ble.start(
      advertiseData: AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 1234,
        manufacturerData: Uint8List.fromList(sessionId.codeUnits),
      ),
    );
  }

  static Future<void> stopAdvertising() async {
    debugPrint("🔴 BLE STOPPED");
    await _ble.stop();
  }
}
