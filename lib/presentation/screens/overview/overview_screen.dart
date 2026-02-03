import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../providers.dart';

final overviewProvider = FutureProvider<OverviewData>((ref) async {
  final repo = ref.watch(coffeeOrderRepositoryProvider);
  final orders = await repo.fetchOrdersWithTotals();
  final total = orders.fold(0.0, (sum, item) => sum + item.total);
  return OverviewData(
    totalOrders: orders.length,
    totalRevenue: total,
    pendingPackages: orders.where((item) => !item.hasPackages).length,
  );
});

class OverviewData {
  OverviewData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingPackages,
  });

  final int totalOrders;
  final double totalRevenue;
  final int pendingPackages;
}

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(overviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
      ),
      body: overviewAsync.when(
        data: (data) => Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    title: 'Pedidos registrados',
                    value: data.totalOrders.toString(),
                    icon: Icons.local_cafe,
                    isWide: isWide,
                  ),
                  _SummaryCard(
                    title: 'Total estimado',
                    value: Formatters.money.format(data.totalRevenue),
                    icon: Icons.attach_money,
                    isWide: isWide,
                  ),
                  _SummaryCard(
                    title: 'Pendientes de empaques',
                    value: data.pendingPackages.toString(),
                    icon: Icons.shopping_bag,
                    isWide: isWide,
                  ),
                ],
              );
            },
          ),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isWide,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWide ? 260 : double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
