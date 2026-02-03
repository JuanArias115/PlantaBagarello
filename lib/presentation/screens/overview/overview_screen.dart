import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../providers.dart';
import '../../widgets/app_bar_logo.dart';
import '../../widgets/app_bar_title.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(overviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(subtitle: 'Resumen mensual'),
        leading: const AppBarLogo(),
        leadingWidth: 96,
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
                    title: 'Pedidos del mes',
                    value: data.totalOrders.toString(),
                    icon: Icons.local_cafe,
                    isWide: isWide,
                  ),
                  _SummaryCard(
                    title: 'Total empacado del mes',
                    value: Formatters.money.format(data.totalRevenue),
                    icon: Icons.attach_money,
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
