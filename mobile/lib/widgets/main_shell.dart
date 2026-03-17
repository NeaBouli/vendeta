import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/scan'))    return 1;
    if (loc.startsWith('/rewards')) return 2;
    if (loc.startsWith('/wallet'))  return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: .5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex(context),
          onTap: (i) {
            switch (i) {
              case 0: context.go('/map');
              case 1: context.go('/scan');
              case 2: context.go('/rewards');
              case 3: context.go('/wallet');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Karte'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), activeIcon: Icon(Icons.qr_code_scanner), label: 'Scannen'),
            BottomNavigationBarItem(icon: Icon(Icons.stars_outlined), activeIcon: Icon(Icons.stars), label: 'Credits'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          ],
        ),
      ),
    );
  }
}
