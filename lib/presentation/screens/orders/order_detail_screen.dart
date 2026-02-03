import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers.dart';
import '../../widgets/app_bar_logo.dart';
import '../../widgets/app_bar_title.dart';
import 'orders_list_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pedido'),
        content: const Text('¿Quieres eliminar este pedido y sus empaques?'),
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

    await ref.read(coffeeOrderRepositoryProvider).delete(orderId);
    ref.invalidate(ordersProvider);
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(orderTotalProvider(orderId));

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido eliminado.')),
    );
    context.go('/orders');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final totalAsync = ref.watch(orderTotalProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(subtitle: 'Detalle del pedido'),
        leading: const AppBarLogo(),
        leadingWidth: 96,
        actions: [
          IconButton(
            onPressed: () => context.go('/orders/$orderId/edit'),
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: () => context.go('/orders/$orderId/packages'),
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'Empaques',
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
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
                      const SizedBox(height: 12),
                      Text(
                        'Observación: ${order.observation ?? 'Sin observación'}',
                      ),
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
                label: const Text('Empaques / Liquidación'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/orders/$orderId/checkout'),
                icon: const Icon(Icons.phone),
                label: const Text('Liquidación y WhatsApp'),
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
