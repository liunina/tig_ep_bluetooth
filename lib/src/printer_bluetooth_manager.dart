import 'dart:async';
import 'dart:io';

import 'package:tig_bluetooth_basic/tig_bluetooth_basic.dart';
import 'package:tig_ep_bluetooth/src/abstract_printer_bluetooth.dart';
import 'package:tig_ep_bluetooth/src/android_printer_bluetooth.dart';
import 'package:tig_ep_bluetooth/src/ios_printer_bluetooth.dart';
import 'package:tig_ep_bluetooth/tig_ep_bluetooth.dart';
import 'package:tig_ep_utils/tig_ep_utils.dart';

typedef ScanResultsCallback =  Function(List<PrinterBluetoothLocal>);
typedef BlueStateCallback =  Function(int);

class PrinterBluetoothManager {
  static const int STATE_OFF = 10;
  static const int STATE_TURNING_ON = 11;

  static const int CONNECTED = 1;
  static const int DISCONNECTED = 0;
  BlueStateCallback callback;

  AbstractPrinterBluetooth _printerBluetooth;

  PrinterBluetoothManager(BlueStateCallback callback) {
    this.callback = callback;
    if (Platform.isAndroid) {
      _printerBluetooth = AndroidPrinterBluetooth((event) {
        callback.call(event);
      });
    } else {
      _printerBluetooth = IosPrinterBluetooth((event) {
        callback.call(event);
      });
    }
  }

  Future<bool> connect(PrinterBluetoothLocal bluetooth){
    return _printerBluetooth.connect(bluetooth);
  }

  Future<bool> disconnect(PrinterBluetoothLocal bluetooth){
    return _printerBluetooth.disconnect(bluetooth);
  }

  void startScan(Duration timeout, ScanResultsCallback callback) {
    _printerBluetooth.startScan(timeout, callback);
  }

  void stopScan() {
    _printerBluetooth.stopScan();
  }

  Future<PosPrintResult> writeBytes(
    List<int> bytes,
    PrinterBluetoothLocal bluetooth, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
  }) {
    return _printerBluetooth.writeBytes(
        bytes, bluetooth, chunkSizeBytes, queueSleepTimeMs);
  }

  ///
  /// 开始打印
  ///
  Future<PosPrintResult> printTicket(
    Ticket ticket,
    PrinterBluetoothLocal bluetooth, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
  }) async {
    if (ticket == null || ticket.bytes.isEmpty) {
      return Future<PosPrintResult>.value(PosPrintResult.ticketEmpty);
    }
    return writeBytes(
      ticket.bytes,
      bluetooth,
      chunkSizeBytes: chunkSizeBytes,
      queueSleepTimeMs: queueSleepTimeMs,
    );
  }
}

/// Bluetooth printer
class PrinterBluetooth {
  PrinterBluetooth(this.device);

  final BluetoothDevice device;

  String get name => device.name;

  String get address => device.address;

  int get type => device.type;
}

class PrinterBluetoothLocal {
  String name;
  String mac;

  PrinterBluetoothLocal({this.name, this.mac});

  factory PrinterBluetoothLocal.fromJson(Map<String, dynamic> json) {
    return PrinterBluetoothLocal(
      name: json['name'] as String,
      mac: json['mac'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'mac': mac, 'name': name};
  }
}
