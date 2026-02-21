import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/coffee_order_repository.dart';
import '../../providers.dart';

final overviewProvider = FutureProvider<OverviewData>((ref) async {
  final orders = await ref.watch(ordersWithTotalsProvider.future);
  final total = orders.fold(0.0, (sum, item) => sum + item.total);
  return OverviewData(
    totalOrders: orders.length,
    totalRevenue: total,
    pendingPackages: orders.where((item) => !item.hasPackages).length,
  );
});

class OverviewData {
  OverviewData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingPackages,
  });

  final int totalOrders;
  final double totalRevenue;
  final int pendingPackages;
}

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(overviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          IconButton(
            tooltip: 'Exportar reporte mensual PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportMonthlyReport(context, ref),
          ),
        ],
      ),
      body: overviewAsync.when(
        data: (data) => Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    title: 'Pedidos registrados',
                    value: data.totalOrders.toString(),
                    icon: Icons.local_cafe,
                    isWide: isWide,
                  ),
                  _SummaryCard(
                    title: 'Total estimado',
                    value: Formatters.money.format(data.totalRevenue),
                    icon: Icons.attach_money,
                    isWide: isWide,
                  ),
                  _SummaryCard(
                    title: 'Pendientes de empaques',
                    value: data.pendingPackages.toString(),
                    icon: Icons.shopping_bag,
                    isWide: isWide,
                  ),
                ],
              );
            },
          ),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _exportMonthlyReport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    try {
      final orders = await ref.read(ordersWithTotalsProvider.future);
      final monthlyOrders = orders.where((item) {
        final date = item.order.arrivalDate;
        return date.year == now.year && date.month == now.month;
      }).toList();

      if (monthlyOrders.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No hay pedidos en el mes actual para exportar.'),
          ),
        );
        return;
      }

      final bytes = await _buildMonthlyReportPdf(
        monthlyOrders: monthlyOrders,
        generatedAt: now,
      );

      await Printing.layoutPdf(
        name:
            'reporte_mensual_${now.year}_${now.month.toString().padLeft(2, '0')}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el reporte mensual en PDF.'),
        ),
      );
    }
  }

  Future<Uint8List> _buildMonthlyReportPdf({
    required List<OrderListItem> monthlyOrders,
    required DateTime generatedAt,
  }) async {
    final document = pw.Document();

    final totalValue = monthlyOrders.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    final monthLabel =
        DateFormat('MMMM yyyy', 'es_CO').format(generatedAt).toUpperCase();

    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Reporte mensual de clientes',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Mes actual: $monthLabel'),
          pw.Text('Registros: ${monthlyOrders.length}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['Nombre', 'Fecha', 'Lote', 'Valor final'],
            data: monthlyOrders
                .map(
                  (item) => [
                    item.order.customerName,
                    Formatters.arrivalDate.format(item.order.arrivalDate),
                    '${Formatters.kg.format(item.order.lotKg)} kg',
                    Formatters.money.format(item.total),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignments: {
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total mes actual: ${Formatters.money.format(totalValue)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isWide,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWide ? 260 : double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
