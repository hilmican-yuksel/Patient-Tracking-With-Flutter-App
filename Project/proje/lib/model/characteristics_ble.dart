import 'package:flutter_blue/flutter_blue.dart';

class BleCharacteristics {  
   static String uId = "0000ffe0-0000-1000-8000-00805f9b34fb";  
   static BluetoothDevice _connectedDevice;
   static List<BluetoothService> _services;
   static bool isConnected = false;
   // function 
   static String getUID() { 
      return uId.toUpperCase(); 
   } 

   static setServices(List<BluetoothService> services){
     _services = services;
   }
   static List<BluetoothService> getServices(){
     return _services;
   }
   static addConnectedDevice(BluetoothDevice device){
     _connectedDevice=device;
     isConnected=true;
   }
   static removeConnectedDevice(BluetoothDevice device){
     if(device!=null)
     _connectedDevice=null;
     isConnected=false;
   }
   
   static Future<BluetoothDevice> getConnectedDevice() async{
     List<BluetoothDevice> connectedDevices = await FlutterBlue.instance.connectedDevices;
     if(connectedDevices.length>0) {
      BleCharacteristics.addConnectedDevice(connectedDevices[0]);
    }else
      removeConnectedDevice(null);
     return _connectedDevice;
   }
}