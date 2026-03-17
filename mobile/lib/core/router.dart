import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/map/map_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/rewards/rewards_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../widgets/main_shell.dart';

final router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
        GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
        GoRoute(path: '/rewards', builder: (context, state) => const RewardsScreen()),
        GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
      ],
    ),
  ],
);
