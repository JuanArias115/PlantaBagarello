import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/coffee_order_repository.dart';
import '../../providers.dart';
import '../../widgets/responsive_grid.dart';

final ordersProvider = FutureProvider<List<OrderListItem>>((ref) async {
  final repo = ref.watch(coffeeOrderRepositoryProvider);
  return repo.fetchOrdersWithTotals();
});

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/orders/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo pedido'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('Aún no hay pedidos registrados.'),
            );
          }
          return ResponsiveGrid(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final item = orders[index];
              return GestureDetector(
                onTap: () => context.go('/orders/${item.order.id}'),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.order.customerName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.order.customerAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text('Tel: ${item.order.customerPhone}'),
                        const Spacer(),
                        Text('Lote: ${Formatters.kg.format(item.order.lotKg)} kg'),
                        const SizedBox(height: 4),
                        Text('Llegada: ${Formatters.arrivalDate.format(item.order.arrivalDate)}'),
                        const SizedBox(height: 8),
                        Text(
                          item.hasPackages
                              ? 'Total: ${Formatters.money.format(item.total)}'
                              : 'Sin empaques',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
