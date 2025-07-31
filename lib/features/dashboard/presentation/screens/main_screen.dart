import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'dashboard_screen.dart';
import '../../../clients/presentation/screens/clients_screen.dart';
import '../../../projects/presentation/screens/projects_screen.dart';
import '../../../payments/presentation/screens/payments_screen.dart';
import '../../../auth/presentation/screens/profile_screen.dart';

/// Main screen with bottom navigation and content pages
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const ClientsScreen(),
    const ProjectsScreen(),
    const PaymentsScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(PhosphorIconsRegular.house),
      activeIcon: Icon(PhosphorIconsFill.house),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(PhosphorIconsRegular.users),
      activeIcon: Icon(PhosphorIconsFill.users),
      label: 'Clients',
    ),
    const BottomNavigationBarItem(
      icon: Icon(PhosphorIconsRegular.folder),
      activeIcon: Icon(PhosphorIconsFill.folder),
      label: 'Projects',
    ),
    const BottomNavigationBarItem(
      icon: Icon(PhosphorIconsRegular.creditCard),
      activeIcon: Icon(PhosphorIconsFill.creditCard),
      label: 'Payments',
    ),
    const BottomNavigationBarItem(
      icon: Icon(PhosphorIconsRegular.user),
      activeIcon: Icon(PhosphorIconsFill.user),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _currentIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconTheme(
                          data: IconThemeData(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 24,
                          ),
                          child: isSelected ? item.activeIcon! : item.icon!,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}