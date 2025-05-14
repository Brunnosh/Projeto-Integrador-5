import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/inserir_despesas.dart';
import 'pages/inserir_receitas.dart';
import 'pages/receitas_detalhadas.dart';
import 'pages/despesas_detalhadas.dart';
import 'pages/dashboard.dart';

void main() {
  runApp(const MyFinanceApp());
}

class MyFinanceApp extends StatelessWidget {
  const MyFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFinance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/inserir-despesas': (context) => const InserirDespesaPage(),
        '/inserir-receitas': (context) => const InserirReceitaPage(),
        '/receitas-detalhadas': (context) => const ReceitasDetalhadasPage(),
        '/despesas-detalhadas': (context) => const DespesasDetalhadasPage(),
        '/dashboard': (context) => DashboardPage(),
      },
    );
  }
}
