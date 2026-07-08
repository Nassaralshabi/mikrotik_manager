import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  bool _isConnected = false;
  String? _connectedMacAddress;

  bool get isConnected => _isConnected;
  String? get connectedMacAddress => _connectedMacAddress;

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    return allGranted;
  }

  Future<bool> checkBluetoothStatus() async {
    bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    return isBluetoothEnabled;
  }

  Future<List<BluetoothInfo>> getBluetoothDevices() async {
    if (!await checkPermissions()) {
      throw Exception('Bluetooth and Location permissions are required.');
    }
    
    if (!await checkBluetoothStatus()) {
      throw Exception('Bluetooth is disabled.');
    }

    try {
      final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;
      return listResult;
    } catch (e) {
      throw Exception('Failed to get paired devices: $e');
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (result) {
        _isConnected = true;
        _connectedMacAddress = macAddress;
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      if (result) {
        _isConnected = false;
        _connectedMacAddress = null;
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<bool> printVoucher({
    required String hotspotName,
    required String username,
    required String password,
    required String price,
    required String validity,
  }) async {
    if (!_isConnected) return false;

    try {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        _isConnected = false;
        return false;
      }

      // print_bluetooth_thermal writeString uses "size///text" internally.
      // we just use the PrintTextSize class.
      
      // Header
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 2, text: "$hotspotName\n"));
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "--------------------------------\n"));
      
      // Details
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 2, text: "Username : $username\n"));
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 2, text: "Password : $password\n"));
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "Price    : $price\n"));
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "Validity : $validity\n"));
      
      // Footer
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "--------------------------------\n"));
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "Thank You / Terima Kasih\n"));
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "Powered by OMMON\n"));
      
      // Empty lines to feed paper
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "\n\n\n"));

      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }
}
