class OrderPackageItem {
  OrderPackageItem({
    this.id,
    required this.orderId,
    required this.packageTypeId,
    required this.quantity,
    required this.unitPriceSnapshot,
  });

  final int? id;
  final int orderId;
  final int packageTypeId;
  final int quantity;
  final double unitPriceSnapshot;

  double get lineTotal => quantity * unitPriceSnapshot;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'package_type_id': packageTypeId,
      'quantity': quantity,
      'unit_price_snapshot': unitPriceSnapshot,
    };
  }

  factory OrderPackageItem.fromMap(Map<String, Object?> map) {
    return OrderPackageItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      packageTypeId: map['package_type_id'] as int,
      quantity: map['quantity'] as int,
      unitPriceSnapshot: (map['unit_price_snapshot'] as num).toDouble(),
    );
  }
}
