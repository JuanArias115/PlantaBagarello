import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../data/models/coffee_order.dart';
import '../../../data/models/order_package_item.dart';
import '../../../data/models/package_type.dart';
import '../../providers.dart';

class OrderCheckoutState {
  OrderCheckoutState({
    required this.order,
    required this.items,
    required this.packageTypes,
  });

  final CoffeeOrder order;
  final List<OrderPackageItem> items;
  final List<PackageType> packageTypes;

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);
}

final orderCheckoutProvider =
    FutureProvider.family<OrderCheckoutState?, int>((ref, orderId) async {
  final order =
      await ref.read(coffeeOrderRepositoryProvider).fetchById(orderId);
  if (order == null) {
    return null;
  }
  final items =
      await ref.read(orderPackageRepositoryProvider).fetchByOrderId(orderId);
  final packageTypes = await ref.read(packageTypeRepositoryProvider).fetchAll();
  return OrderCheckoutState(
    order: order,
    items: items,
    packageTypes: packageTypes,
  );
});

class OrderCheckoutScreen extends ConsumerWidget {
  const OrderCheckoutScreen({super.key, required this.orderId});

  final int orderId;

  Future<void> _sendWhatsApp(
      BuildContext context, OrderCheckoutState data) async {
    final phone = PhoneUtils.normalize(data.order.customerPhone);
    final text = _buildReceipt(data);
    final uri = Uri.parse(
      'https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(text)}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  String _buildReceipt(OrderCheckoutState data) {
    final buffer = StringBuffer()
      ..writeln('☕ Planta Bagarello')
      ..writeln('Cliente: ${data.order.customerName}')
      ..writeln('Tel: ${data.order.customerPhone}')
      ..writeln(
        'Llegada: ${Formatters.arrivalDate.format(data.order.arrivalDate)}',
      )
      ..writeln('Lote: ${Formatters.kg.format(data.order.lotKg)} kg')
      ..writeln('Tueste: ${data.order.roastType}')
      ..writeln('Molido: ${data.order.grindType}')
      ..writeln('Observación: ${data.order.observation ?? 'Sin observación'}')
      ..writeln('--- Empaques ---');

    if (data.items.isEmpty) {
      buffer.writeln('Sin empaques registrados.');
    } else {
      for (final item in data.items) {
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
        buffer.writeln(
          '${type.name} x${item.quantity} = ${Formatters.money.format(item.lineTotal)}',
        );
      }
    }

    buffer.writeln('TOTAL: ${Formatters.money.format(data.total)}');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutAsync = ref.watch(orderCheckoutProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen y checkout'),
      ),
      body: checkoutAsync.when(
        data: (data) {
          if (data == null) {
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
                        data.order.customerName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Tel: ${data.order.customerPhone}'),
                      Text(
                        'Llegada: ${Formatters.arrivalDate.format(data.order.arrivalDate)}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Lote: ${Formatters.kg.format(data.order.lotKg)} kg'),
                      Text('Tueste: ${data.order.roastType}'),
                      Text('Molido: ${data.order.grindType}'),
                      if (data.order.observation != null)
                        Text('Observación: ${data.order.observation}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Empaques',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (data.items.isEmpty) const Text('Sin empaques registrados.'),
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
                    trailing: Text(Formatters.money.format(item.lineTotal)),
                  );
                }),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Total final'),
                  subtitle: Text(Formatters.money.format(data.total)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _sendWhatsApp(context, data),
                icon: const Icon(Icons.phone),
                label: const Text('Enviar por WhatsApp'),
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
