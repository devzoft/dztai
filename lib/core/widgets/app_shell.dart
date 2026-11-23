import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _index(String location) {
    if (location.startsWith('/discover') || location.startsWith('/model')) {
      return 1;
    }
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _index(location);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isCompact = MediaQuery.of(context).size.width < 380;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 252,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.accent,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DevZoft',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'AI WORKSPACE',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: FilledButton.icon(
                        onPressed: () => context.go('/chat'),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: const Text('New conversation'),
                        style: FilledButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 16, 10),
                      child: Text(
                        'WORKSPACE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _SidebarDestination(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      selected: idx == 0,
                      onTap: () => context.go('/chat'),
                    ),
                    _SidebarDestination(
                      icon: Icons.travel_explore_rounded,
                      label: 'Discover models',
                      selected: idx == 1,
                      onTap: () => context.go('/discover'),
                    ),
                    _SidebarDestination(
                      icon: Icons.history_rounded,
                      label: 'History',
                      selected: idx == 2,
                      onTap: () => context.go('/history'),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your key stays on this device',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SidebarDestination(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      selected: idx == 3,
                      onTap: () => context.go('/settings'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: keyboardVisible
          ? null
          : NavigationBar(
              labelBehavior: isCompact
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: idx,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/chat');
                    break;
                  case 1:
                    context.go('/discover');
                    break;
                  case 2:
                    context.go('/history');
                    break;
                  case 3:
                    context.go('/settings');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.travel_explore_outlined),
                  selectedIcon: Icon(Icons.travel_explore_rounded),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.accent : colors.onSurfaceVariant,
        ),
        title: Text(label),
        selected: selected,
        selectedColor: AppColors.accent,
        selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
