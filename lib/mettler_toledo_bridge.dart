library mettler_toledo_bridge;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

/// Supported Mettler Toledo device models
enum MettlerToledoDeviceModel {
  ind231,
}

/// Supported Mettler Toledo device communication types
enum MettlertoledoCommunicationType {
  usb,
  ethernet,
}

/// Supported Mettler Toledo device protocols
enum MettlertoledoProtocol {
  sics,
  continuous,
}

/// A Mettler Toledo device
class MettlerToledoDevice {
  /// The model of the device
  MettlerToledoDeviceModel model;

  /// The communication type of the device
  MettlertoledoCommunicationType communicationType;

  /// The protocol of the device
  MettlertoledoProtocol protocol;

  /// The address of the device. For USB devices, this is the device path,
  /// e.g. tty/USB0.
  /// For Ethernet devices, this is the IP address. e.g. 192.168.1.1:4001
  String address;

  /// The decoder to use for the device
  StreamTransformer<String, MettlerToledoData> get decoder {
    switch (protocol) {
      case MettlertoledoProtocol.sics:
        throw Exception('SICS protocol not supported yet');
      case MettlertoledoProtocol.continuous:
        return _continuousDecoder();
    }
  }

  StreamTransformer<String, MettlerToledoData> _continuousDecoder() {
    return StreamTransformer<String, MettlerToledoData>.fromHandlers(
      handleData: (String line, EventSink<MettlerToledoData> sink) {
        debugPrint('Received: $line');
        final data = parseContinuousData(line);

        sink.add(data);
      },
    );
  }

  MettlerToledoDevice({
    required this.model,
    required this.communicationType,
    required this.protocol,
    required this.address,
  });
}

MettlerToledoData parseContinuousData(String input) {
  final status = input.substring(0, 3);
  final rawWeight = int.parse(input.substring(3, 9));
  final rawTare =
      int.tryParse(input.length > 9 ? input.substring(9, 15) : '') ?? 0;

  int decimalPointLocation =
      _getDeciamlPointLocation(status[0].binary.substring(5, 8));

  final statusTypeBBinary = status[1].binary;
  final statusTypeCBinary = status[2].binary;

  MettlertoledoDataWeightType weightType = statusTypeBBinary[7] == '0'
      ? MettlertoledoDataWeightType.gross
      : MettlertoledoDataWeightType.net;
  bool isPositive = statusTypeBBinary[6] == '0';
  bool isOutOfRange = statusTypeBBinary[5] == '1';
  bool isStable = statusTypeBBinary[4] == '0';
  bool isDataExpanded = statusTypeCBinary[3] == '1';
  MettlerToledoDataUnit unit = _getSubUnit(statusTypeCBinary.substring(5, 8)) ??
      _getUnit(statusTypeBBinary[3]);
  return MettlerToledoData(
    deciamlPointLocation: decimalPointLocation,
    weightType: weightType,
    isPositive: isPositive,
    isStable: isStable,
    unit: unit,
    isOutOfRange: isOutOfRange,
    isDataExpanded: isDataExpanded,
    rawWeight: rawWeight,
    rawTare: rawTare,
  );
}

MettlerToledoDataUnit _getUnit(String input) {
  switch (input) {
    case '0':
      return MettlerToledoDataUnit.lb;
    case '1':
      return MettlerToledoDataUnit.kg;
    default:
      throw Exception('Invalid unit');
  }
}

MettlerToledoDataUnit? _getSubUnit(String input) {
  switch (input) {
    case '001':
      return MettlerToledoDataUnit.g;
    case '011':
      return MettlerToledoDataUnit.oz;
    default:
      return null;
  }
}

int _getDeciamlPointLocation(String input) {
  switch (input) {
    case '000':
      return 0;
    case '001':
      return 0;
    case '010':
      return 0;
    case '011':
      return 1;
    case '100':
      return 2;
    case '101':
      return 3;
    case '110':
      return 4;
    case '111':
      return 5;
    default:
      return 0;
  }
}

enum MettlerToledoDataStatus {
  stable,
  unstable,
}

enum MettlertoledoDataWeightType {
  gross,
  net,
}

enum MettlerToledoDataUnit {
  kg,
  g,
  lb,
  oz,
}

class MettlerToledoData {
  int deciamlPointLocation;
  MettlertoledoDataWeightType weightType;
  bool isPositive;
  bool isStable;
  MettlerToledoDataUnit unit;
  bool isOutOfRange;
  bool isDataExpanded;
  int rawWeight;
  int rawTare;

  double get weight =>
      rawWeight / pow(10, deciamlPointLocation) * (isPositive ? 1 : -1);

  double get tareWeight => rawTare / pow(10, deciamlPointLocation);

  double get netWeight => weight;

  double get grossWeight => weight + tareWeight;

  MettlerToledoData({
    this.deciamlPointLocation = 0,
    this.weightType = MettlertoledoDataWeightType.gross,
    this.isPositive = true,
    this.isStable = true,
    this.unit = MettlerToledoDataUnit.kg,
    this.isOutOfRange = false,
    this.isDataExpanded = false,
    this.rawWeight = 0,
    this.rawTare = 0,
  });
}

/// A Mettler Toledo device bridge
class MettlerToledoBridge {
  /// The device to connect to
  MettlerToledoDevice device;

  MettlerToledoBridge({required this.device}) {
    connect();
  }

  late Stream<MettlerToledoData> _stream;
  SerialPort? _port;

  /// Connect to the device
  void connect() {
    switch (device.communicationType) {
      case MettlertoledoCommunicationType.usb:
        // Connect to the device via USB
        _connectUsb();
        break;
      case MettlertoledoCommunicationType.ethernet:
        // Connect to the device via Ethernet
        throw Exception('Ethernet communication not supported yet');
    }
  }

  /// Connect to the device via USB
  void _connectUsb() {
    _port = SerialPort(device.address);
    debugPrint('Opening port: ${device.address}');
    if (!(_port?.openReadWrite() ?? false)) {
      throw Exception('Failed to open port: ${SerialPort.lastError}');
    }

    final reader = SerialPortReader(_port!);
    _stream = reader.stream
        .cast<List<int>>()
        .transform(ascii.decoder)
        .transform(const LineSplitter())
        .transform(Trimer())
        .transform(device.decoder);
  }

  /// Disconnect from the device
  void disconnect() {
    // Disconnect from the device
  }

  /// Read the weight from the device
  double readWeight() {
    // Read the weight from the device
    return 0.0;
  }

  /// Clear the device
  void clear() {
    _port?.write(ascii.encode("C"));
  }

  /// Tare the device
  void tare() {
    _port?.write(ascii.encode("T"));
  }

  /// Send print command to the device
  void print() {
    _port?.write(ascii.encode("P"));
  }

  /// Send zero command to the device
  void zero() {
    _port?.write(ascii.encode("Z"));
  }

  /// Send switch unit command to the device
  void switchUnit() {
    _port?.write(ascii.encode("S"));
  }

  /// Stream of weight readings
  Stream<MettlerToledoData> get stream => _stream;
}

extension _StringExtension on String {
  String get binary =>
      runes.map((rune) => rune.toRadixString(2).padLeft(8, '0')).join('');
}

class Trimer extends StreamTransformerBase<String, String> {
  @override
  Stream<String> bind(Stream<String> stream) {
    return stream.map((event) => event.replaceAll(String.fromCharCode(2), ''));
  }
}
