import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/order_package_item.dart';
import '../../../data/models/package_type.dart';
import '../../providers.dart';
import 'orders_list_screen.dart';

class OrderPackagesState {
  OrderPackagesState({
    required this.packageTypes,
    required this.activePackageTypes,
    required this.items,
  });

  final List<PackageType> packageTypes;
  final List<PackageType> activePackageTypes;
  final List<OrderPackageItem> items;

  double get total =>
      items.fold(0, (sum, item) => sum + item.lineTotal);
}

class OrderPackagesController
    extends StateNotifier<AsyncValue<OrderPackagesState>> {
  OrderPackagesController(this.ref, this.orderId) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref ref;
  final int orderId;

  Future<void> _load() async {
    try {
      final packageTypes =
          await ref.read(packageTypeRepositoryProvider).fetchAll();
      final activeTypes =
          packageTypes.where((type) => type.isActive).toList();
      final items =
          await ref.read(orderPackageRepositoryProvider).fetchByOrderId(orderId);
      state = AsyncValue.data(OrderPackagesState(
        packageTypes: packageTypes,
        activePackageTypes: activeTypes,
        items: items,
      ));
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> upsertItem(PackageType type, int quantity) async {
    final repo = ref.read(orderPackageRepositoryProvider);
    final item = OrderPackageItem(
      orderId: orderId,
      packageTypeId: type.id!,
      quantity: quantity,
      unitPriceSnapshot: type.price,
    );
    await repo.upsertItem(item);
    await _load();
  }

  Future<void> deleteItem(int id) async {
    await ref.read(orderPackageRepositoryProvider).deleteItem(id);
    await _load();
  }
}

final orderPackagesProvider = StateNotifierProvider.family<
    OrderPackagesController, AsyncValue<OrderPackagesState>, int>((ref, orderId) {
  return OrderPackagesController(ref, orderId);
});

class OrderPackagesScreen extends ConsumerStatefulWidget {
  const OrderPackagesScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderPackagesScreen> createState() => _OrderPackagesScreenState();
}

class _OrderPackagesScreenState extends ConsumerState<OrderPackagesScreen> {
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    ref.listen(orderPackagesProvider(widget.orderId), (previous, next) {
      next.whenOrNull(data: (data) {
        for (final item in data.items) {
          _quantities[item.packageTypeId] = item.quantity;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(orderPackagesProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empaques del pedido'),
      ),
      body: packagesAsync.when(
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tipos de empaque activos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...data.activePackageTypes.map((type) {
                final quantity = _quantities[type.id] ?? 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Precio: ${Formatters.money.format(type.price)}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _quantities[type.id!] =
                                      (quantity - 1).clamp(0, 999);
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$quantity',
                                style: Theme.of(context).textTheme.titleMedium),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _quantities[type.id!] =
                                      (quantity + 1).clamp(0, 999);
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () async {
                                if (quantity <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Define una cantidad mayor a 0.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await ref
                                    .read(orderPackagesProvider(widget.orderId).notifier)
                                    .upsertItem(type, quantity);
                                ref.invalidate(ordersProvider);
                              },
                              child: const Text('Agregar/Actualizar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Text(
                'Items actuales',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (data.items.isEmpty)
                const Text('Sin empaques registrados.'),
              if (data.items.isNotEmpty)
                ...data.items.map((item) {
                  final type = data.packageTypes.firstWhere(
                    (type) => type.id == item.packageTypeId,
                    orElse: () => PackageType(
                      id: item.packageTypeId,
                      name: 'Empaque #${item.packageTypeId}',
                      price: item.unitPriceSnapshot,
                      isActive: false,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  return ListTile(
                    title: Text(type.name),
                    subtitle: Text(
                      '${item.quantity} x ${Formatters.money.format(item.unitPriceSnapshot)}',
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        await ref
                            .read(orderPackagesProvider(widget.orderId).notifier)
                            .deleteItem(item.id!);
                        ref.invalidate(ordersProvider);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Total actual'),
                  subtitle: Text(Formatters.money.format(data.total)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/orders/${widget.orderId}/checkout'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Ir a checkout'),
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
