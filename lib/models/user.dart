class User {
  final int? id;
  final String email;
  final String name;
  final String password;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'name': name,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      password: map['password'] as String? ?? '',
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}
