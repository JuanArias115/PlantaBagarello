import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/package_type.dart';
import '../../providers.dart';
import '../../widgets/app_bar_logo.dart';
import '../../widgets/app_bar_title.dart';
import 'package_types_screen.dart';

class PackageTypeFormScreen extends ConsumerStatefulWidget {
  const PackageTypeFormScreen({super.key, this.packageTypeId});

  final int? packageTypeId;

  @override
  ConsumerState<PackageTypeFormScreen> createState() =>
      _PackageTypeFormScreenState();
}

class _PackageTypeFormScreenState
    extends ConsumerState<PackageTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _gramsController = TextEditingController();
  bool _isActive = true;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded || widget.packageTypeId == null) {
      return;
    }
    final packageType = await ref
        .read(packageTypeRepositoryProvider)
        .fetchById(widget.packageTypeId!);
    if (packageType != null) {
      _nameController.text = packageType.name;
      _priceController.text = packageType.price.toStringAsFixed(0);
      _gramsController.text = packageType.gramsPerPackage.toStringAsFixed(0);
      _isActive = packageType.isActive;
    }
    _loaded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final price = double.parse(_priceController.text.replaceAll(',', '.'));
    final grams = double.parse(_gramsController.text.replaceAll(',', '.'));

    if (widget.packageTypeId == null) {
      final package = PackageType(
        name: _nameController.text.trim(),
        price: price,
        gramsPerPackage: grams,
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(packageTypeRepositoryProvider).insert(package);
    } else {
      final existing = await ref
          .read(packageTypeRepositoryProvider)
          .fetchById(widget.packageTypeId!);
      if (existing != null) {
        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          price: price,
          gramsPerPackage: grams,
          isActive: _isActive,
          updatedAt: now,
        );
        await ref.read(packageTypeRepositoryProvider).update(updated);
      }
    }

    ref.invalidate(packageTypesProvider);
    if (mounted) {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    _load();

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          subtitle:
              widget.packageTypeId == null ? 'Nuevo empaque' : 'Editar empaque',
        ),
        leading: const AppBarLogo(),
        leadingWidth: 96,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo requerido'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Campo requerido';
                }
                final number = double.tryParse(text.replaceAll(',', '.'));
                if (number == null || number <= 0) {
                  return 'Debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gramsController,
              decoration: const InputDecoration(labelText: 'Gramaje (g)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Campo requerido';
                }
                final number = double.tryParse(text.replaceAll(',', '.'));
                if (number == null || number <= 0) {
                  return 'Debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activo'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
