import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MaterialApp(home: BleScanner()));
}

class BleScanner extends StatefulWidget {
  const BleScanner({super.key});

  @override
  State<BleScanner> createState() => _BleScannerState();
}

class _BleScannerState extends State<BleScanner> {
  final List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    debugPrint("🔍 Startar BLE-scan...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    FlutterBluePlus.scanResults.listen((results) {
      debugPrint("📡 Hittade ${results.length} enheter");
      setState(() {
        devices.clear();
        devices.addAll(results);
      });
    });
  }

  double calculateDistance(int rssi, int txPower, double n) {
    // Log-distance path loss model
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // Sortera efter starkast RSSI
    List<ScanResult> sortedDevices = [...devices];
    sortedDevices.sort((a, b) => b.rssi.compareTo(a.rssi));

    final nearest = sortedDevices.isNotEmpty ? sortedDevices.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Närmaste BLE-enhet')),
      body: nearest == null
          ? const Center(child: Text("🔍 Inga enheter hittades ännu"))
          : Padding(
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
                      Text(
                        'Uppskattat avstånd: ${calculateDistance(nearest.rssi, -59, 2.0).toStringAsFixed(2)} m',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}