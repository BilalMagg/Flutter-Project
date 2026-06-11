class Category {
  final int? id;
  final String name;
  final int colorIndex;
  final String icon;

  Category({
    this.id,
    required this.name,
    this.colorIndex = 0,
    this.icon = 'list',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'colorIndex': colorIndex,
      'icon': icon,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      colorIndex: map['colorIndex'] as int? ?? 0,
      icon: map['icon'] as String? ?? 'list',
    );
  }

  Category copyWith({
    int? id,
    String? name,
    int? colorIndex,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorIndex': colorIndex,
      'icon': icon,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      colorIndex: json['colorIndex'] as int? ?? 0,
      icon: json['icon'] as String? ?? 'list',
    );
  }
}
