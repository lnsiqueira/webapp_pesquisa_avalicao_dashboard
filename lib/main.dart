import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/firebase_options.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/user_model.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/screens/home_screen.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoBen - Benefícios Corporativos',
      theme: AppTheme.theme,
      home: const LoginScreen(),
      // home: HomeScreen(
      //   loggedInUser: User(
      //       id: 'id',
      //       name: 'name',
      //       role: 'role',
      //       email: 'email',
      //       avatar: 'avatar'),
      // ),
      debugShowCheckedModeBanner: false,
    );
  }
}
