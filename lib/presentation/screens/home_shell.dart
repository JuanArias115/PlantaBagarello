import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  static const List<_NavigationItem> _items = [
    _NavigationItem(label: 'Resumen', icon: Icons.insights, location: '/overview'),
    _NavigationItem(label: 'Pedidos', icon: Icons.local_cafe, location: '/orders'),
    _NavigationItem(label: 'Configuración', icon: Icons.settings, location: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _items.indexWhere((item) => location.startsWith(item.location));

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 1 : currentIndex,
        onDestinationSelected: (index) {
          context.go(_items[index].location);
        },
        destinations: _items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.location,
  });

  final String label;
  final IconData icon;
  final String location;
}
