import 'package:flutter_blue/flutter_blue.dart';

class BluetoothServices {
  static Guid uUId = new Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
  static Guid alertUUID = new Guid("0X2A06");
  static BluetoothCharacteristic c;
  static List<BluetoothService> _services;
  
  static Future<List<BluetoothService>> getCharacteristics(
      BluetoothDevice device) async {
    return await device.discoverServices();
  }

  static writeToDevice(bool state, BluetoothDevice device) {
    getCharacteristics(device).then((value) {
      _services = value;
      c = _services[2].characteristics.first;
      if (state)
        c.write([0x00]); // off
      else
        c.write([0x01]); // on
    });
  }
}
