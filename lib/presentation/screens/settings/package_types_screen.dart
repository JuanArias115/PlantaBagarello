import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/package_type.dart';
import '../../providers.dart';

final packageTypesProvider = FutureProvider<List<PackageType>>((ref) async {
  return ref.watch(packageTypeRepositoryProvider).fetchAll();
});

class PackageTypesScreen extends ConsumerWidget {
  const PackageTypesScreen({super.key});

  Future<void> _deleteType(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar empaque'),
        content: const Text('¿Seguro que quieres eliminar este empaque?'),
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

    if (confirmed != true) {
      return;
    }
    await ref.read(packageTypeRepositoryProvider).delete(id);
    ref.invalidate(packageTypesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packageTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de empaques'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/settings/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo empaque'),
      ),
      body: packagesAsync.when(
        data: (packages) {
          if (packages.isEmpty) {
            return const Center(child: Text('No hay tipos de empaque.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final item = packages[index];
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    Formatters.money.format(item.price),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/settings/${item.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _deleteType(context, ref, item.id!),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
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
