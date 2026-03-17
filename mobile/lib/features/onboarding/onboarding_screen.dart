import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final _ctrl = PageController();

  static const _pages = [
    _OnboardData(emoji: '👋', title: 'Willkommen bei\nVendetta',
      subtitle: 'Finde günstige Preise in deiner Nähe\nund verdiene Belohnungen dafür.', btn: 'Loslegen'),
    _OnboardData(emoji: '📱', title: 'Nummer bestätigen',
      subtitle: 'Nur zur einmaligen Bestätigung.\nWir speichern sie nicht.', btn: 'Weiter', hasPhone: true),
    _OnboardData(emoji: '📍', title: 'Standort erlauben',
      subtitle: 'Damit du Preise in deiner Nähe\nfinden und melden kannst.', btn: 'Standort erlauben'),
    _OnboardData(emoji: '✓', title: 'Bereit!',
      subtitle: 'Scanne deinen ersten Preis\nund verdiene Credits.', btn: 'Zur Karte', isLast: true),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.go('/map');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 24 : 8, height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == _page ? AppColors.orange : AppColors.border,
                ),
              )),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _pages.length,
              itemBuilder: (ctx, i) => _buildPage(ctx, _pages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _next, child: Text(_pages[_page].btn)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(data.emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 32),
        Text(data.title, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: data.isLast ? AppColors.green : AppColors.text)),
        const SizedBox(height: 16),
        Text(data.subtitle, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted, height: 1.6)),
        if (data.hasPhone) ...[
          const SizedBox(height: 32),
          const TextField(
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(hintText: '+49 123 456 7890', prefixIcon: Icon(Icons.phone, color: AppColors.muted)),
          ),
        ],
      ]),
    );
  }
}

class _OnboardData {
  final String emoji, title, subtitle, btn;
  final bool hasPhone, isLast;
  const _OnboardData({required this.emoji, required this.title, required this.subtitle, required this.btn, this.hasPhone = false, this.isLast = false});
}
