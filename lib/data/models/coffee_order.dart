class CoffeeOrder {
  CoffeeOrder({
    this.id,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.arrivalDate,
    required this.lotKg,
    required this.roastType,
    required this.grindType,
    this.observation,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final DateTime arrivalDate;
  final double lotKg;
  final String roastType;
  final String grindType;
  final String? observation;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoffeeOrder copyWith({
    int? id,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    DateTime? arrivalDate,
    double? lotKg,
    String? roastType,
    String? grindType,
    String? observation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoffeeOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      lotKg: lotKg ?? this.lotKg,
      roastType: roastType ?? this.roastType,
      grindType: grindType ?? this.grindType,
      observation: observation ?? this.observation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'arrival_date': arrivalDate.millisecondsSinceEpoch,
      'lot_kg': lotKg,
      'roast_type': roastType,
      'grind_type': grindType,
      'observation': observation,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory CoffeeOrder.fromMap(Map<String, Object?> map) {
    return CoffeeOrder(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String,
      customerAddress: map['customer_address'] as String,
      customerPhone: map['customer_phone'] as String,
      arrivalDate:
          DateTime.fromMillisecondsSinceEpoch(map['arrival_date'] as int),
      lotKg: (map['lot_kg'] as num).toDouble(),
      roastType: map['roast_type'] as String,
      grindType: map['grind_type'] as String,
      observation: map['observation'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
