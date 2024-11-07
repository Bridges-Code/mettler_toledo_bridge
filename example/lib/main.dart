import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:mettler_toledo_bridge/mettler_toledo_bridge.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final device = MettlerToledoDevice(
      model: MettlerToledoDeviceModel.ind231,
      communicationType: MettlertoledoCommunicationType.usb,
      protocol: MettlertoledoProtocol.continuous,
      address: SerialPort.availablePorts[1]);
  late final mtBridge = MettlerToledoBridge(device: device);
  MettlerToledoData? data;

  @override
  void initState() {
    super.initState();
    mtBridge.stream.listen((data) {
      setState(() {
        this.data = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mettler Toledo Bridge Example'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Is Stable: ${data?.isStable}'),
          ),
          ListTile(
            title: Text('Net: ${data?.netWeight} ${data?.unit.name}'),
          ),
          ListTile(
            title: Text('Gross: ${data?.grossWeight} ${data?.unit.name}'),
          ),
          ListTile(
            title: Text('Tare: ${data?.tareWeight} ${data?.unit.name}'),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    mtBridge.clear();
                  },
                  child: const Text('Clear'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    mtBridge.tare();
                  },
                  child: const Text('Tare'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    mtBridge.print();
                  },
                  child: const Text('Print'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    mtBridge.zero();
                  },
                  child: const Text('Zero'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    mtBridge.switchUnit();
                  },
                  child: const Text('Switch'),
                ),
              ),
            ]
                .map((child) => const Padding(padding: EdgeInsets.all(8)))
                .toList(),
          )
        ],
      ),
    );
  }
}
