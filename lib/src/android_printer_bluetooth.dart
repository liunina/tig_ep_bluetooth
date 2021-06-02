import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:tig_ep_bluetooth/src/abstract_printer_bluetooth.dart';
import 'package:tig_ep_bluetooth/src/enums.dart';
import 'package:tig_ep_bluetooth/src/printer_bluetooth_manager.dart';

class AndroidPrinterBluetooth extends AbstractPrinterBluetooth {
  BlueThermalPrinter bluetoothPrinter = BlueThermalPrinter.instance;

  AndroidPrinterBluetooth(callback) : super(callback) {
    bluetoothPrinter.onStateChanged().listen((event) {
      callback.call(event);
    });
  }

  @override
  Future<void> startScan(Duration timeout, callback) async {
    List<BluetoothDevice> bluetoothList = [];
    try {
      bluetoothList = await bluetoothPrinter.getBondedDevices();
      if (bluetoothList != null && bluetoothList.length > 0) {
        List<PrinterBluetoothLocal> list = [];
        for (int i = 0; i < bluetoothList.length; i++) {
          BluetoothDevice device = bluetoothList[i];
          PrinterBluetoothLocal data =
              PrinterBluetoothLocal(name: device.name, mac: device.address);
          list.add(data);
        }
        callback.call(list);
      }
    } on PlatformException {}
  }

  @override
  void stopScan() {
    //android 只选择设配过的
  }

  @override
  // ignore: missing_return
  Future<PosPrintResult> writeBytes(
      List<int> bytes,
      PrinterBluetoothLocal bluetooth,
      int chunkSizeBytes,
      int queueSleepTimeMs) {
    bluetoothPrinter.isConnected.then((isConnected) async {
      if (!isConnected) {
        return connectAndPrinter(bytes, bluetooth);
      } else {
        bluetoothPrinter.disconnect().then((value) {
          return connectAndPrinter(bytes, bluetooth);
        }).catchError((onError) {
          return PosPrintResult.disconnectError;
        });
      }
    });
  }

  // ignore: missing_return
  Future<PosPrintResult> connectAndPrinter(
    List<int> bytes,
    PrinterBluetoothLocal bluetooth,
  ) async {
    await bluetoothPrinter
        .connect(BluetoothDevice(bluetooth.name, bluetooth.mac))
        .catchError((error) {
      return PosPrintResult.connectError;
    }).then((value) {
      if (value == true) {
        bluetoothPrinter.writeBytes(Uint8List.fromList(bytes)).then((value) {
          if (value) {
            return PosPrintResult.success;
          } else {
            return PosPrintResult.otherError;
          }
        });
      } else {
        return PosPrintResult.connectError;
      }
    });
  }

  @override
  Future<bool> connect(PrinterBluetoothLocal bluetooth) async {
    return await bluetoothPrinter.connect(BluetoothDevice(bluetooth.name, bluetooth.mac)).catchError((error) {
      return false;
    });
  }

  @override
  Future<bool> disconnect(PrinterBluetoothLocal bluetooth) async {
    return await bluetoothPrinter.disconnect().catchError((onError) {
      return false;
    });
  }

  @override
  Future<bool> isConnected() async {
   return await bluetoothPrinter.isConnected;
  }
}
