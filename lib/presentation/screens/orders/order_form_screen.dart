import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/coffee_order.dart';
import '../../providers.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _lotController = TextEditingController();
  final _observationController = TextEditingController();

  DateTime? _arrivalDate;
  String _roastType = 'medio';
  String _grindType = 'medio';
  String _unit = 'kg';

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _lotController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_arrivalDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de llegada.')),
      );
      return;
    }

    final rawLot = double.parse(_lotController.text.replaceAll(',', '.'));
    final lotKg = _unit == 'kg' ? rawLot : rawLot * 0.453592;
    final now = DateTime.now();

    final order = CoffeeOrder(
      customerName: _nameController.text.trim(),
      customerAddress: _addressController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      arrivalDate: _arrivalDate!,
      lotKg: lotKg,
      roastType: _roastType,
      grindType: _grindType,
      observation: _observationController.text.trim().isEmpty
          ? null
          : _observationController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(coffeeOrderRepositoryProvider).insert(order);
    ref.invalidate(ordersWithTotalsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido guardado.')),
      );
      context.go('/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo pedido'),
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
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Dirección'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo requerido'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Campo requerido';
                }
                final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 7) {
                  return 'Mínimo 7 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lotController,
                    decoration: const InputDecoration(labelText: 'Lote'),
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
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _unit,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lb', child: Text('lb')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _unit = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _roastType,
              decoration: const InputDecoration(labelText: 'Tipo de tueste'),
              items: const [
                DropdownMenuItem(value: 'alto', child: Text('Alto')),
                DropdownMenuItem(value: 'medio', child: Text('Medio')),
                DropdownMenuItem(value: 'bajo', child: Text('Bajo')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _roastType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _grindType,
              decoration: const InputDecoration(labelText: 'Molido'),
              items: const [
                DropdownMenuItem(value: 'fino', child: Text('Fino')),
                DropdownMenuItem(value: 'medio', child: Text('Medio')),
                DropdownMenuItem(value: 'grueso', child: Text('Grueso')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _grindType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationController,
              decoration: const InputDecoration(
                labelText: 'Observación',
                hintText: 'Mitad en grano, mitad molido. Bolsas de 200gr.',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _arrivalDate == null
                    ? 'Selecciona fecha de llegada'
                    : 'Fecha: ${_arrivalDate!.day}/${_arrivalDate!.month}/${_arrivalDate!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (selected != null) {
                  setState(() => _arrivalDate = selected);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Guardar pedido'),
            ),
          ],
        ),
      ),
    );
  }
}
