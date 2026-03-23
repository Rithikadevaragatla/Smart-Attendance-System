import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter/foundation.dart';

class BleService {
  static final FlutterBlePeripheral _ble = FlutterBlePeripheral();

  static Future<void> startAdvertising(String payload) async {
    debugPrint("🔵 BLE STARTED");
    debugPrint("Broadcasting sessionId: $payload");

    await _ble.start(
      advertiseData: AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 1234,
        manufacturerData: Uint8List.fromList(payload.codeUnits),
      ),
    );
  }

  static Future<void> stopAdvertising() async {
    debugPrint("🔴 BLE STOPPED");
    await _ble.stop();
  }
}
