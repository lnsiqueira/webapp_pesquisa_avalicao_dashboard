class LoginUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String avatar;
  final String role;
  final bool isAdmin;
  final String? adminType;

  LoginUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.avatar,
    required this.role,
    this.isAdmin = false,
    this.adminType,
  });
}

class LoginService {
  static final List<LoginUser> mockUsers = [
    LoginUser(
      id: 'USR001',
      name: 'Ana Silva da Costa',
      email: 'ana.silva@donadeola.com',
      password: '123456',
      avatar: 'assets/images/ana-costa.jpeg',
      role: 'Desenvolvedora Sênior',
      isAdmin: false,
    ),
  ];

  static LoginUser? authenticate(String email, String password) {
    try {
      final user = mockUsers.firstWhere(
        (u) => u.email == email && u.password == password,
      );
      return user;
    } catch (e) {
      return null;
    }
  }

  static List<LoginUser> getAllUsers() {
    return mockUsers;
  }
}
