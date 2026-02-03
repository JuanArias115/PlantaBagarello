import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/coffee_order.dart';
import '../../providers.dart';
import '../../widgets/app_bar_logo.dart';
import '../../widgets/app_bar_title.dart';
import 'orders_list_screen.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key, this.orderId});

  final int? orderId;

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
  bool _isLoading = false;
  CoffeeOrder? _existingOrder;

  bool get _isEditing => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadOrder();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _lotController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order =
        await ref.read(coffeeOrderRepositoryProvider).fetchById(widget.orderId!);
    if (!mounted) {
      return;
    }
    if (order == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido no encontrado.')),
      );
      context.go('/orders');
      return;
    }

    _existingOrder = order;
    _nameController.text = order.customerName;
    _addressController.text = order.customerAddress;
    _phoneController.text = order.customerPhone;
    _lotController.text = order.lotKg.toStringAsFixed(2);
    _observationController.text = order.observation ?? '';
    setState(() {
      _arrivalDate = order.arrivalDate;
      _roastType = order.roastType;
      _grindType = order.grindType;
      _unit = 'kg';
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isEditing && _existingOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el pedido.')),
      );
      return;
    }

    final arrivalDate =
        _isEditing ? (_arrivalDate ?? DateTime.now()) : DateTime.now();
    final rawLot = double.parse(_lotController.text.replaceAll(',', '.'));
    final lotKg = _unit == 'kg' ? rawLot : rawLot * 0.453592;
    final now = DateTime.now();

    final order = CoffeeOrder(
      id: _existingOrder?.id,
      customerName: _nameController.text.trim(),
      customerAddress: _addressController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      arrivalDate: arrivalDate,
      lotKg: lotKg,
      roastType: _roastType,
      grindType: _grindType,
      observation: _observationController.text.trim().isEmpty
          ? null
          : _observationController.text.trim(),
      createdAt: _existingOrder?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      await ref.read(coffeeOrderRepositoryProvider).update(order);
    } else {
      await ref.read(coffeeOrderRepositoryProvider).insert(order);
    }
    ref.invalidate(ordersProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEditing ? 'Pedido actualizado.' : 'Pedido guardado.'),
        ),
      );
      if (_isEditing) {
        context.go('/orders/${order.id}');
      } else {
        context.go('/orders');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            AppBarTitle(subtitle: _isEditing ? 'Editar pedido' : 'Nuevo pedido'),
        leading: const AppBarLogo(),
        leadingWidth: 96,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Campo requerido';
                            }
                            final number =
                                double.tryParse(text.replaceAll(',', '.'));
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
                    decoration:
                        const InputDecoration(labelText: 'Tipo de tueste'),
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
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    child:
                        Text(_isEditing ? 'Actualizar pedido' : 'Guardar pedido'),
                  ),
                ],
              ),
            ),
    );
  }
}
