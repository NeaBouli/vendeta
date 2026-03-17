import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../bridge/vendetta_bridge.dart';
import 'price_entry_sheet.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _scanning = true;
  String? _lastEan;
  final _manualCtrl = TextEditingController();

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _onEanDetected(String ean) async {
    if (!_scanning) return;
    final valid = await VendettaBridge.instance.validateEan(ean);
    if (!valid) return;

    setState(() {
      _scanning = false;
      _lastEan = ean;
    });

    if (!mounted) return;
    await _showPriceEntry(ean);
    setState(() => _scanning = true);
  }

  Future<void> _showPriceEntry(String ean) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PriceEntrySheet(ean: ean),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('Preis scannen')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Scan area placeholder
            Container(
              width: 240,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _scanning ? AppColors.orange : AppColors.green,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  _scanning ? Icons.qr_code_scanner : Icons.check_circle,
                  size: 48,
                  color: _scanning ? AppColors.orange : AppColors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  _scanning ? 'Kamera-Scanner' : 'EAN: $_lastEan',
                  style: TextStyle(color: _scanning ? AppColors.muted : AppColors.green, fontSize: 13),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Text(
              _scanning ? 'Barcode auf Preisschild richten' : 'EAN erkannt!',
              style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kamera-Scan wird in Production aktiv\n(mobile_scanner Paket installiert)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 32),
            // Manual EAN input
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _manualCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'EAN manuell eingeben',
                    prefixIcon: Icon(Icons.edit, color: AppColors.muted, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final ean = _manualCtrl.text.trim();
                  if (ean.isNotEmpty) _onEanDetected(ean);
                },
                child: const Text('OK'),
              ),
            ]),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _showPriceEntry('MANUAL'),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.orange)),
              child: const Text('Preis ohne EAN eingeben', style: TextStyle(color: AppColors.orange)),
            ),
          ]),
        ),
      ),
    );
  }
}
