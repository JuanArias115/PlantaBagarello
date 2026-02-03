class PackageType {
  PackageType({
    this.id,
    required this.name,
    required this.price,
    required this.gramsPerPackage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final double price;
  final double gramsPerPackage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PackageType copyWith({
    int? id,
    String? name,
    double? price,
    double? gramsPerPackage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackageType(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      gramsPerPackage: gramsPerPackage ?? this.gramsPerPackage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'grams_per_package': gramsPerPackage,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory PackageType.fromMap(Map<String, Object?> map) {
    return PackageType(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      gramsPerPackage: (map['grams_per_package'] as num?)?.toDouble() ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
