import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../bridge/vendetta_bridge.dart';

class PriceEntrySheet extends StatefulWidget {
  final String ean;
  const PriceEntrySheet({super.key, required this.ean});

  @override
  State<PriceEntrySheet> createState() => _PriceEntrySheetState();
}

class _PriceEntrySheetState extends State<PriceEntrySheet> {
  final _priceCtrl = TextEditingController();
  final _bridge = VendettaBridge.instance;
  bool _submitting = false;
  String? _error;
  String _currency = 'EUR';

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.qr_code, color: AppColors.muted, size: 16),
            const SizedBox(width: 6),
            Text(
              widget.ean == 'MANUAL' ? 'Manuelle Eingabe' : 'EAN: ${widget.ean}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Preis eingeben',
              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: .5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: _currency,
                dropdownColor: AppColors.bg2,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                items: ['EUR', 'GBP', 'CHF', 'PLN']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                style: const TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 24),
                ),
              ),
            ),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Preis speichern'),
            ),
          ),
        ]),
      );

  Future<void> _submit() async {
    final priceText = _priceCtrl.text.trim();
    if (priceText.isEmpty) {
      setState(() => _error = 'Bitte Preis eingeben');
      return;
    }
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() => _error = 'Ungültiger Preis');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final cents = _bridge.priceToCents(price);
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final hash = await _bridge.generateHash(
        ean: widget.ean,
        priceCents: cents,
        latitude: 48.1372,
        longitude: 11.5761,
        timestamp: ts,
        userId: 'user_hash_placeholder',
      );

      debugPrint('Submission hash: $hash');
      debugPrint('Price: $cents cents $_currency');

      // TODO Session 12: send to blockchain
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preis gespeichert! +50 Credits'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Fehler: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }
}
