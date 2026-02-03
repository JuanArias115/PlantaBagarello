import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/coffee_order.dart';
import '../../providers.dart';

final orderDetailProvider =
    FutureProvider.family<CoffeeOrder?, int>((ref, orderId) async {
  final repo = ref.watch(coffeeOrderRepositoryProvider);
  return repo.fetchById(orderId);
});

final orderTotalProvider =
    FutureProvider.family<double, int>((ref, orderId) async {
  final repo = ref.watch(coffeeOrderRepositoryProvider);
  return repo.fetchOrderTotal(orderId);
});

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final totalAsync = ref.watch(orderTotalProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del pedido'),
        actions: [
          IconButton(
            onPressed: () => context.go('/orders/$orderId/packages'),
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'Empaques',
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Pedido no encontrado.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(order.customerAddress),
                      const SizedBox(height: 8),
                      Text('Tel: ${order.customerPhone}'),
                      const Divider(height: 32),
                      Text('Lote: ${Formatters.kg.format(order.lotKg)} kg'),
                      Text(
                        'Llegada: ${Formatters.arrivalDate.format(order.arrivalDate)}',
                      ),
                      Text('Tueste: ${order.roastType}'),
                      Text('Molido: ${order.grindType}'),
                      if (order.observation != null) ...[
                        const SizedBox(height: 12),
                        Text('Observación: ${order.observation}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              totalAsync.when(
                data: (total) => Card(
                  child: ListTile(
                    title: const Text('Total actual'),
                    subtitle: Text(Formatters.money.format(total)),
                  ),
                ),
                error: (error, stack) => Text('Error: $error'),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/orders/$orderId/packages'),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Empaques / Checkout'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/orders/$orderId/checkout'),
                icon: const Icon(Icons.whatsapp),
                label: const Text('Resumen y WhatsApp'),
              ),
            ],
          );
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
