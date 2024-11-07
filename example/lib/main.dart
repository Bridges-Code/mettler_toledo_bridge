import 'dart:developer';

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

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mettler Toledo Bridge Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final device = MettlerToledoDevice(
              model: MettlerToledoDeviceModel.ind231,
              communicationType: MettlertoledoCommunicationType.usb,
              protocol: MettlertoledoProtocol.continuous,
              address: SerialPort.availablePorts.first,
            );

            final bridge = MettlerToledoBridge(device: device);

            bridge.stream.listen((data) {
              log('''Net weight: ${data.netWeight}
Gross weight: ${data.grossWeight}
Tare weight: ${data.tareWeight}
Unit: ${data.unit.name}
Stable: ${data.isStable}
''');
            });
          },
          child: const Text('Connect to Mettler Toledo Device'),
        ),
      ),
    );
  }
}
