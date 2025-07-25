import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(home: BleScanner()));
}

class BleScanner extends StatefulWidget {
  const BleScanner({super.key});

  @override
  State<BleScanner> createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      startScan();  // ✅ Kör både scan + lyssning
    });
  }

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  void startScan() {
    debugPrint("🔍 Startar BLE-scan...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    /*
    FlutterBluePlus.scanResults.listen((results) {
      debugPrint('scanResults.listen anropad. Hittade ${results.length} enheter');

      for (var result in results) {
        final name = result.device.name.isEmpty ? '(okänd)' : result.device.name;
        final id = result.device.id.id;
        final rssi = result.rssi;
        if (results.length > 500 && rssi > -50) {
          debugPrint('🔁 Avläst (nära enhet): $name ($id) RSSI=$rssi');
        }
      }
  });
  */

  FlutterBluePlus.scanResults.listen((results) {
    if (results.isEmpty) return;

    // Hitta enheten med högst RSSI = närmast
    ScanResult closest = results.reduce((a, b) => a.rssi > b.rssi ? a : b);

    final rssi = closest.rssi.toDouble();
    final distance = calculateDistance(rssi);
    final name = closest.device.name.isNotEmpty ? closest.device.name : "(okänd)";
    final mac = closest.device.id.id;

    debugPrint("🎯 Närmaste enhet: $name ($mac)  RSSI=$rssi  Avstånd ≈ ${distance.toStringAsFixed(2)} m");
  });



}


  /*
  double calculateDistance(int rssi, int txPower, double n) {
    // Log-distance path loss model
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }
  */
  double calculateDistance(double rssi, {double txPower = -59, double n = 2.0}) {
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }


  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Närmaste BLE-enhet')),
        body: Center(child: Text("🔍 Inga enheter hittades ännu")),
      );
    }

    final sorted = [...devices];
    sorted.sort((a, b) => b.rssi.compareTo(a.rssi));
    final nearest = sorted.first;

    final distance =
        calculateDistance(nearest.rssi.toDouble()).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(title: const Text('Närmaste BLE-enhet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nearest.device.name.isEmpty
                      ? '(okänd enhet)'
                      : nearest.device.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text('MAC-adress: ${nearest.device.id.id}'),
                Text('RSSI: ${nearest.rssi} dBm'),
                Text('Uppskattat avstånd: $distance m'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}