/*
 * esc_pos_bluetooth
 * Created by Andrey Ushakov
 * 
 * Copyright (c) 2019-2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:async';
import 'dart:io';

import 'package:rxdart/rxdart.dart';
import 'package:tig_bluetooth_basic/tig_bluetooth_basic.dart';
import 'package:tig_ep_bluetooth/src/abstract_printer_bluetooth.dart';
import 'package:tig_ep_bluetooth/tig_ep_bluetooth.dart';

/// Printer Bluetooth Manager
class IosPrinterBluetooth extends AbstractPrinterBluetooth {
  final BluetoothManager _bluetoothManager = BluetoothManager.instance;
  bool _isPrinting = false;
  bool _isConnected = false;
  StreamSubscription _scanResultsSubscription;
  StreamSubscription _isScanningSubscription;
  PrinterBluetooth _selectedPrinter;

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);

  IosPrinterBluetooth(callback) : super(callback);

  Stream<bool> get isScanningStream => _isScanning.stream;

  final BehaviorSubject<List<PrinterBluetooth>> _scanResults =
      BehaviorSubject.seeded([]);

  Stream<List<PrinterBluetooth>> get scanResults => _scanResults.stream;

  Future _runDelayed(int seconds) {
    return Future<dynamic>.delayed(Duration(seconds: seconds));
  }

  ///
  /// 开始扫描周围蓝牙设备
  @override
  void startScan(Duration timeout, ScanResultsCallback callback) async {
    _scanResults.add(<PrinterBluetooth>[]);

    _bluetoothManager.startScan(timeout: timeout);

    _scanResultsSubscription = _bluetoothManager.scanResults.listen((devices) {
      _scanResults.add(devices.map((d) => PrinterBluetooth(d)).toList());
      if (_scanResults != null && _scanResults.value.length > 0) {
        List<PrinterBluetoothLocal> data = [];
        for (int i = 0; i < _scanResults.value.length; i++) {
          data.add(PrinterBluetoothLocal(
              name: _scanResults.value[i].name,
              mac: _scanResults.value[i].address));
        }
        callback.call(data);
      }
    });

    _isScanningSubscription =
        _bluetoothManager.isScanning.listen((isScanningCurrent) async {
      // If isScanning value changed (scan just stopped)
      if (_isScanning.value && !isScanningCurrent) {
        _scanResultsSubscription.cancel();
        _isScanningSubscription.cancel();
      }
      _isScanning.add(isScanningCurrent);
    });
  }

  ///
  /// 停止扫描蓝牙设备
  @override
  void stopScan() async {
    await _bluetoothManager.stopScan();
  }

  ///
  ///  获取当前已连接的蓝牙设备当前状态监控
  ///
  Stream<int> get state async* {
    yield* _bluetoothManager.state;
  }

  ///
  /// 对蓝牙设备进行写数据
  @override
  Future<PosPrintResult> writeBytes(
    List<int> bytes,
    PrinterBluetoothLocal bluetooth,
    int chunkSizeBytes,
    int queueSleepTimeMs,
  ) async {
    final Completer<PosPrintResult> completer = Completer();

    const int timeout = 5;
    if (bluetooth == null) {
      return Future<PosPrintResult>.value(PosPrintResult.printerNotSelected);
    } else if (_isScanning.value) {
      return Future<PosPrintResult>.value(PosPrintResult.scanInProgress);
    } else if (_isPrinting) {
      return Future<PosPrintResult>.value(PosPrintResult.printInProgress);
    }
    BluetoothDevice device = BluetoothDevice();
    device.name = bluetooth.name;
    device.address = bluetooth.mac;
    _selectedPrinter = PrinterBluetooth(device);
    _isPrinting = true;

    // We have to rescan before connecting, otherwise we can connect only once
    await _bluetoothManager.startScan(timeout: Duration(seconds: 1));
    await _bluetoothManager.stopScan();

    // Connect
    await _bluetoothManager.connect(_selectedPrinter.device);

    // Subscribe to the events
    _bluetoothManager.state.listen((state) async {
      callback.call(state);
      switch (state) {
        case BluetoothManager.BLE_OFF:
          print("objec22222222 BLE_OFF");
          break;
        case BluetoothManager.BLE_ON:
          print("objec22222222 BLE_ON");
          break;
        case BluetoothManager.CONNECTED:
          print("objec22222222 CONNECTED");
          // To avoid double call
          if (!_isConnected) {
            final len = bytes.length;
            List<List<int>> chunks = [];
            for (var i = 0; i < len; i += chunkSizeBytes) {
              var end = (i + chunkSizeBytes < len) ? i + chunkSizeBytes : len;
              chunks.add(bytes.sublist(i, end));
            }

            for (var i = 0; i < chunks.length; i += 1) {
              await _bluetoothManager.writeData(chunks[i]);
              sleep(Duration(milliseconds: queueSleepTimeMs));
            }

            completer.complete(PosPrintResult.success);
          }
          // TODO sending disconnect signal should be event-based
          _runDelayed(3).then((dynamic v) async {
            await _bluetoothManager.disconnect();
            _isPrinting = false;
          });
          _isConnected = true;
          break;
        case BluetoothManager.DISCONNECTED:
          _isConnected = false;
          print("objec22222222 DISCONNECTED");
          break;
        default:
          break;
      }
    });

    // Printing timeout
    _runDelayed(timeout).then((dynamic v) async {
      if (_isPrinting) {
        _isPrinting = false;
        completer.complete(PosPrintResult.timeout);
      }
    });

    return completer.future;
  }

  @override
  Future<bool> connect(PrinterBluetoothLocal bluetooth) async {
    BluetoothDevice device = BluetoothDevice();
    device.name = bluetooth.name;
    device.address = bluetooth.mac;
    return await _bluetoothManager.connect(device);
  }

  @override
  Future<bool> disconnect(PrinterBluetoothLocal bluetooth) async {
    return await _bluetoothManager.disconnect();
  }

  @override
  Future<bool> isConnected() async {
   return await _bluetoothManager.isConnected;
  }
}
