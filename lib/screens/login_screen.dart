import 'package:flutter/material.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/login_users_model.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/user_model.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/screens/home_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simular delay de autenticação
    await Future.delayed(const Duration(milliseconds: 500));

    final loginUser = LoginService.authenticate(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (loginUser != null) {
      // Criar objeto User a partir do LoginUser
      final user = User(
        id: loginUser.id,
        name: loginUser.name,
        role: loginUser.role,
        email: loginUser.email,
        avatar: loginUser.avatar,
        isAdmin: loginUser.isAdmin,
        adminType: loginUser.adminType,
      );

      // Navegar para HomeScreen passando o usuário autenticado
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen(loggedInUser: user)),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email ou senha inválidos';
      });
    }
  }

  void _fillUserCredentials(LoginUser user) {
    _emailController.text = user.email;
    _passwordController.text = user.password;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  /// Layout Mobile (apenas formulário)
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildLoginForm(),
            const SizedBox(height: 40),
            //_buildTestUsersSection(true),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Layout Desktop (formulário + imagem lado a lado)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Lado esquerdo: Formulário
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 48),
                  //  _buildTestUsersSection(false),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        // Lado direito: Imagem com opacidade
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Programa-de-Engajamento-scaled-2.jpg',
                ),
                fit: BoxFit.cover,
                opacity: 0.5, // Opacidade baixa
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget do Formulário de Login
  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo e Título
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset('assets/images/logo.png', width: 300),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'Bem vindo Dashboard',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Center(
            child: Text(
              'Gerencie seus dados de forma fácil e rápida',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
            ),
          ),
          const SizedBox(height: 48),

          // Campo Email
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'seu.email@bencorp.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryRed,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Campo Senha
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Senha',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryRed,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mensagem de Erro
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
              ),
            ),
          const SizedBox(height: 24),

          // Botão Login
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Widget da Seção de Usuários de Teste
  // Widget _buildTestUsersSection(bool isMobile) {
  //   return Container(
  //     constraints: const BoxConstraints(maxWidth: 400),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Usuários de Teste',
  //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //             fontWeight: FontWeight.bold,
  //             color: AppTheme.textDark,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         GridView.builder(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //             crossAxisCount: isMobile ? 1 : 2,
  //             crossAxisSpacing: 12,
  //             mainAxisSpacing: 12,
  //             childAspectRatio: isMobile ? 3.5 : 2.5,
  //           ),
  //           itemCount: LoginService.getAllUsers().length,
  //           itemBuilder: (context, index) {
  //             final user = LoginService.getAllUsers()[index];
  //             return _buildUserCard(user);
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Widget do Card de Usuário
  Widget _buildUserCard(LoginUser user) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
      child: InkWell(
        onTap: () {
          _fillUserCredentials(user);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(user.avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Admin',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.role,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
