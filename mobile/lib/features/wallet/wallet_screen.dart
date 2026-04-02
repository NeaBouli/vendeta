import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_service.dart';

final _balanceProvider = FutureProvider<WalletBalance>(
    (ref) => WalletService.instance.getBalance());

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = WalletService.instance;
    if (!svc.hasWallet) return const _SetupScreen();

    final bal = ref.watch(_balanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.muted),
            onPressed: () => _showSheet(context, const _SettingsSheet()),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: () => ref.refresh(_balanceProvider.future),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _BalanceCard(balance: bal.value ?? WalletBalance.empty, loading: bal.isLoading),
          const SizedBox(height: 14),
          _ActionRow(),
          const SizedBox(height: 14),
          const _LockCard(),
          const SizedBox(height: 14),
          const _HistorySection(),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

void _showSheet(BuildContext ctx, Widget sheet) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: AppColors.bg2,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => sheet,
  );
}

// ── Setup Screen ──────────────────────────

class _SetupScreen extends StatefulWidget {
  const _SetupScreen();
  @override
  State<_SetupScreen> createState() => _SetupState();
}

class _SetupState extends State<_SetupScreen> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Wallet')),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.account_balance_wallet, size: 72, color: AppColors.muted),
            const SizedBox(height: 28),
            const Text('Dein Wallet',
                style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
              'Dein persönliches Wallet wird automatisch und sicher erstellt. Keine Registrierung nötig.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating
                    ? null
                    : () async {
                        setState(() => _creating = true);
                        await WalletService.instance.createWallet();
                        if (mounted) setState(() => _creating = false);
                      },
                child: _creating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Wallet einrichten'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showSheet(context, const _RestoreSheet()),
              child: const Text('Vorhandenes Wallet wiederherstellen',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ]),
        ),
      );
}

// ── Balance Card ──────────────────────────

class _BalanceCard extends StatelessWidget {
  final WalletBalance balance;
  final bool loading;
  const _BalanceCard({required this.balance, required this.loading});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: .5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('IFR Balance', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                const SizedBox(height: 4),
                loading
                    ? Container(
                        width: 120, height: 36,
                        decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(4)))
                    : Text('${balance.ifr.toStringAsFixed(4)} IFR',
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 28, fontWeight: FontWeight.w700)),
              ]),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: balance.address));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Adresse kopiert'), duration: Duration(seconds: 2)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.copy, size: 11, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(WalletService.instance.shortAddress(balance.address),
                      style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                ]),
              ),
            ),
          ]),
          const Divider(height: 24, color: AppColors.border),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Text('ETH  ', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              Text(balance.eth.toStringAsFixed(6),
                  style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
            const Text('Für Transaktionen', style: TextStyle(color: AppColors.muted, fontSize: 10)),
          ]),
        ]),
      );
}

// ── Action Row ────────────────────────────

class _ActionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
        _ActionBtn(Icons.qr_code_2, 'Empfangen', AppColors.blue,
            () => _showSheet(context, _ReceiveSheet(address: WalletService.instance.address ?? ''))),
        const SizedBox(width: 10),
        _ActionBtn(Icons.north, 'Senden', AppColors.muted, () => _showSheet(context, const _SendSheet())),
        const SizedBox(width: 10),
        _ActionBtn(Icons.swap_horiz, 'Tauschen', AppColors.orange, () => _showSheet(context, const _SwapSheet())),
      ]);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: .5),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );
}

// ── Lock Card ─────────────────────────────

class _LockCard extends StatelessWidget {
  const _LockCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withAlpha(60), width: .5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.lock_outline, color: AppColors.amber, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Mehr Credits verdienen',
                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(10)),
              child: const Text('FREE', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          const Text('Sperre IFR und erhalte bis zu 2x mehr Credits beim Scannen.',
              style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('IFR Lock — kommt in Phase 3'), backgroundColor: AppColors.amber));
              },
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.amber.withAlpha(120))),
              child: const Text('IFR sperren', style: TextStyle(color: AppColors.amber, fontSize: 13)),
            ),
          ),
        ]),
      );
}

// ── History ───────────────────────────────

class _HistorySection extends StatelessWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Verlauf', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: .5),
          ),
          child: const Center(
            child: Column(children: [
              Icon(Icons.history, color: AppColors.muted, size: 32),
              SizedBox(height: 8),
              Text('Noch keine Transaktionen', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ]),
          ),
        ),
      ]);
}

// ── Bottom Sheets ─────────────────────────

class _ReceiveSheet extends StatelessWidget {
  final String address;
  const _ReceiveSheet({required this.address});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const SizedBox(height: 20),
          const Text('Empfangen', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.qr_code, size: 80, color: Colors.black87)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.bg3, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: SelectableText(address,
                style: const TextStyle(color: AppColors.text, fontSize: 11), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: address));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse kopiert')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Adresse kopieren'),
            ),
          ),
        ]),
      );
}

class _SendSheet extends StatelessWidget {
  const _SendSheet();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _handle(),
          const SizedBox(height: 20),
          const Text('IFR senden', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const TextField(
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              labelText: 'Empfänger (0x...)',
              labelStyle: TextStyle(color: AppColors.muted),
              prefixIcon: Icon(Icons.account_circle, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0.00', hintStyle: TextStyle(color: AppColors.muted, fontSize: 22),
              labelText: 'IFR Betrag', labelStyle: TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senden — kommt in Phase 3'), backgroundColor: AppColors.amber));
              },
              icon: const Icon(Icons.north, size: 16),
              label: const Text('Senden bestätigen'),
            ),
          ),
        ]),
      );
}

class _SwapSheet extends StatelessWidget {
  const _SwapSheet();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const SizedBox(height: 20),
          const Text('Tauschen', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w600)),
          const Text('Via Uniswap V2 · IFR/ETH', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 20),
          const TextField(
            style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Von: ETH', labelStyle: TextStyle(color: AppColors.muted),
              hintText: '0.00', hintStyle: TextStyle(color: AppColors.muted, fontSize: 22),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.bg3, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.swap_vert, color: AppColors.orange, size: 20),
          ),
          const SizedBox(height: 8),
          const TextField(
            readOnly: true,
            style: TextStyle(color: AppColors.muted, fontSize: 22),
            decoration: InputDecoration(
              labelText: 'Nach: IFR', labelStyle: TextStyle(color: AppColors.muted),
              hintText: '~ 0.00', hintStyle: TextStyle(color: AppColors.muted, fontSize: 22),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Swap — kommt in Phase 3'), backgroundColor: AppColors.amber));
              },
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Tauschen'),
            ),
          ),
        ]),
      );
}

class _RestoreSheet extends StatefulWidget {
  const _RestoreSheet();
  @override
  State<_RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends State<_RestoreSheet> {
  final _ctrl = TextEditingController();
  bool _restoring = false;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wallet wiederherstellen',
              style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Gib deine 12 Sicherheitswörter ein (durch Leerzeichen getrennt).',
              style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(color: AppColors.text, fontSize: 13),
            decoration: InputDecoration(hintText: 'wort1 wort2 wort3 ...', hintStyle: const TextStyle(color: AppColors.muted), errorText: _error),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _restoring ? null : () async {
                setState(() { _restoring = true; _error = null; });
                final ok = await WalletService.instance.restoreFromMnemonic(_ctrl.text.trim());
                if (ok && mounted) { Navigator.pop(context); }
                else if (mounted) { setState(() { _restoring = false; _error = 'Ungültige Sicherheitswörter'; }); }
              },
              child: _restoring
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Wiederherstellen'),
            ),
          ),
        ]),
      );
}

Future<void> _showBackup(BuildContext context) async {
  Navigator.pop(context);
  final m = await WalletService.instance.getMnemonicForBackup();
  if (m == null) return;
  // ignore: use_build_context_synchronously
  if (!context.mounted) return;
  showDialog(context: context, builder: (ctx) => _BackupDialog(mnemonic: m));
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wallet Einstellungen',
              style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.backup, color: AppColors.muted, size: 20),
            title: const Text('Sicherheitskopie', style: TextStyle(color: AppColors.text, fontSize: 13)),
            subtitle: const Text('12 Sicherheitswörter anzeigen', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            onTap: () => _showBackup(context),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: AppColors.muted, size: 20),
            title: const Text('Adresse kopieren', style: TextStyle(color: AppColors.text, fontSize: 13)),
            subtitle: Text(WalletService.instance.shortAddress(WalletService.instance.address ?? ''),
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            onTap: () {
              Clipboard.setData(ClipboardData(text: WalletService.instance.address ?? ''));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse kopiert')));
            },
            contentPadding: EdgeInsets.zero,
          ),
        ]),
      );
}

class _BackupDialog extends StatelessWidget {
  final String mnemonic;
  const _BackupDialog({required this.mnemonic});

  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(' ');
    return AlertDialog(
      backgroundColor: AppColors.bg2,
      title: const Text('Sicherheitskopie', style: TextStyle(color: AppColors.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bg3, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.amber, width: .5),
          ),
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(words.length, (i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(4)),
              child: Text('${i + 1}. ${words[i]}', style: const TextStyle(color: AppColors.text, fontSize: 11)),
            )),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Auf Papier notieren — niemals digital speichern',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.amber, fontSize: 10)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Schließen', style: TextStyle(color: AppColors.muted))),
      ],
    );
  }
}

Widget _handle() => Center(
      child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))));
