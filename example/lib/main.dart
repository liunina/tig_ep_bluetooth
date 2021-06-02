import 'package:tig_ep_bluetooth/tig_ep_bluetooth.dart';
import 'package:tig_ep_utils/tig_ep_utils.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:oktoast/oktoast.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Bluetooth demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Bluetooth demo'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<PrinterBluetoothLocal> _devices = [];
  PrinterBluetoothManager printerBluetoothManger;

  @override
  void initState() {
    super.initState();
    _logState();
    printerBluetoothManger = PrinterBluetoothManager((event) {
      print("哈哈哈哈哈哈哈哈哈哈111：evern:$event");
    });
  }

  Future<void> _logState() async {
    // bool isAvailable = await printerManager.isAvailable;
    // print("22222 isAvailable: $isAvailable");

    // bool isOn = await printerManager.isOn;
    // print("333333 isOn: $isOn");
    //
    // printerManager.state.listen((state) {
    //   switch (state) {
    //     case BluetoothManager.BLE_OFF:
    //       print("object1111 BLE_OFF");
    //       break;
    //     case BluetoothManager.BLE_ON:
    //       print("object1111 BLE_ON");
    //       break;
    //     case BluetoothManager.CONNECTED:
    //       print("object1111 CONNECTED");
    //       break;
    //     case BluetoothManager.DISCONNECTED:
    //       print("object1111 DISCONNECTED");
    //       break;
    //     default:
    //       break;
    //   }
    // });
  }

  void _startScanDevices() {
    // _logState();
    setState(() {
      _devices = [];
    });

    printerBluetoothManger.startScan(Duration(seconds: 4), (data) {
      setState(() {
        _devices = data.cast<PrinterBluetoothLocal>();
      });
    });
  }

  void _stopScanDevices() {
    printerBluetoothManger.stopScan();
  }

  Future<Ticket> testTicket() async {
    final Ticket ticket = Ticket(PaperSize.mm58);

    ticket.text('Bold text', styles: PosStyles(bold: true));
    ticket.text('Reverse text', styles: PosStyles(reverse: true));
    ticket.text('Underlined text', styles: PosStyles(underline: true), linesAfter: 1);
    ticket.text('Align left', styles: PosStyles(align: PosAlign.left));
    ticket.text('Align center', styles: PosStyles(align: PosAlign.center));
    ticket.text('Align right', styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    // Print image
    // final ByteData data = await rootBundle.load('assets/logo.png');
    // final Uint8List bytes = data.buffer.asUint8List();
    // final Image image = decodeImage(bytes);
    // ticket.image(image);
    // Print image using an alternative (obsolette) command
    // ticket.imageRaster(image);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    ticket.barcode(Barcode.upcA(barData));

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    // ticket.text(
    //   'hello ! 中文字 # world @ éphémère &',
    //   styles: PosStyles(codeTable: PosCodeTable.westEur),
    //   containsChinese: true,
    // );

    ticket.feed(2);
    return ticket;
  }

  void _testPrint(PrinterBluetoothLocal printer) async {
    print("current printer is" + printer.name);
    final PosPrintResult res =
        await printerBluetoothManger.printTicket(await testTicket(), printer);
    showToast(res.msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
          itemCount: _devices.length,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () => _testPrint(_devices[index]),
              child: Column(
                children: <Widget>[
                  Container(
                    height: 60,
                    padding: EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _devices[index].name ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                bool ss = await printerBluetoothManger.disconnect();
                                print("88888888888disconnect :$ss");
                              },
                              child: Container(
                                alignment: Alignment.center,
                                margin: EdgeInsets.only(right: 20),
                                padding: EdgeInsets.only(bottom: 4, top: 4, left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  //设置四周圆角 角度
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Text(
                                  "移除",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                PrinterBluetoothLocal blue = PrinterBluetoothLocal();
                                blue.name = _devices[index].name ?? "";
                                blue.mac = _devices[index].mac;
                                bool ss = await printerBluetoothManger.connect(blue);
                                print("88888888888connect :$ss");
                              },
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.only(bottom: 4, top: 4, left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  //设置四周圆角 角度
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Text(
                                  "连接",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                ],
              ),
            );
          }),
      floatingActionButton: StreamBuilder<bool>(
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: _stopScanDevices,
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: _startScanDevices,
            );
          }
        },
      ),
    );
  }
}
