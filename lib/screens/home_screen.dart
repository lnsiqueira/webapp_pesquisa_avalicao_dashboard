import 'package:flutter/material.dart';
import 'package:webapp_pesquisa_avalicao_dashboard/model/user_model.dart';

class HomeScreen extends StatefulWidget {
  final User? loggedInUser;
  final String? loggedInUserName;
  const HomeScreen({Key? key, this.loggedInUser, this.loggedInUserName})
    : assert(
        loggedInUser != null || loggedInUserName != null,
        'Deve passar loggedInUser ou loggedInUserName',
      ),
      super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
