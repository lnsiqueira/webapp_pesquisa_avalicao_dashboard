class User {
  final String id;
  final String name;
  final String role;
  final String email;
  final String avatar;
  final bool isAdmin;
  final String? adminType;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.avatar,
    this.isAdmin = false,
    this.adminType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      adminType: json['adminType'] as String?,
    );
  }
}
