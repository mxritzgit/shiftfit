import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_colors.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.ean8, BarcodeFormat.ean13, BarcodeFormat.upcA],
  );
  bool hasReturned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void handleDetect(BarcodeCapture capture) {
    if (hasReturned) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        hasReturned = true;
        Navigator.of(context).pop(rawValue.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        title: const Text('Barcode scannen'),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: handleDetect),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              key: const ValueKey('barcode-scanner-hint'),
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cyan.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Barcode auf der Packung in den Rahmen halten. ShiftFit lädt dann die Nährwerte aus OpenFoodFacts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, height: 1.3),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cyan, width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                key: const ValueKey('barcode-close-button'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Abbrechen'),
                style: FilledButton.styleFrom(
                  backgroundColor: surfaceSoft,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
