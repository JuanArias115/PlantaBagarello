import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/coffee_order_repository.dart';
import '../../providers.dart';
import '../../widgets/app_bar_logo.dart';
import '../../widgets/app_bar_title.dart';
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

    Future<void> handleMenuAction(
      _OrderMenuAction action,
      OrderListItem item,
    ) async {
      switch (action) {
        case _OrderMenuAction.edit:
          context.go('/orders/${item.order.id}/edit');
          return;
        case _OrderMenuAction.delete:
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Eliminar pedido'),
              content:
                  const Text('¿Quieres eliminar este pedido y sus empaques?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );

          if (confirm != true) {
            return;
          }

          await ref.read(coffeeOrderRepositoryProvider).delete(item.order.id!);
          ref.invalidate(ordersProvider);
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido eliminado.')),
          );
          return;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(subtitle: 'Pedidos'),
        leading: const AppBarLogo(),
        leadingWidth: 96,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.order.customerName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            PopupMenuButton<_OrderMenuAction>(
                              onSelected: (action) =>
                                  handleMenuAction(action, item),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: _OrderMenuAction.edit,
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: _OrderMenuAction.delete,
                                  child: Text('Eliminar'),
                                ),
                              ],
                            ),
                          ],
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
                        Text(
                            'Lote: ${Formatters.kg.format(item.order.lotKg)} kg'),
                        const SizedBox(height: 4),
                        Text(
                            'Llegada: ${Formatters.arrivalDate.format(item.order.arrivalDate)}'),
                        const SizedBox(height: 8),
                        Text(
                          item.hasPackages
                              ? 'Total: ${Formatters.money.format(item.total)}'
                              : 'Sin empaques',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (item.isPendingPackaging) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.go('/orders/${item.order.id}/packages'),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Empacar'),
                          ),
                        ],
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

enum _OrderMenuAction { edit, delete }
