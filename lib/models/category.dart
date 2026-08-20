class Category {
  final int? id;
  final String name;
  final int color; // Color.value (int ARGB)
  final bool isDefault; // Kategori bawaan app — tidak bisa dihapus user

  Category({
    this.id,
    required this.name,
    required this.color,
    this.isDefault = false,
  });

  Category copyWith({
    int? id,
    String? name,
    int? color,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: (map['color'] as num).toInt(),
      isDefault: map['isDefault'] == 1,
    );
  }
}
