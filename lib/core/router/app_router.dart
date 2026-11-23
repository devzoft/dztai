import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_shell.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/models/screens/models_screen.dart';
import '../../features/models/screens/model_details_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/providers/api_key_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final keyState = ref.watch(apiKeyControllerProvider);
  return GoRouter(
    initialLocation: '/chat',
    redirect: (context, state) {
      final hasKey = keyState.valueOrNull != null;
      final onboarding = state.matchedLocation == '/onboarding';
      if (!hasKey && !onboarding) return '/onboarding';
      if (hasKey && onboarding) return '/chat';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(
            path: '/chat/:id',
            builder: (_, s) =>
                ChatScreen(conversationId: s.pathParameters['id']),
          ),
          GoRoute(path: '/discover', builder: (_, __) => const ModelsScreen()),
          GoRoute(
            path: '/model/:id',
            builder: (_, s) => ModelDetailsScreen(
              modelId: Uri.decodeComponent(s.pathParameters['id']!),
            ),
          ),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
