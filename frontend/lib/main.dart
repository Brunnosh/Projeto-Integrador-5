import 'package:flutter/material.dart';
import 'package:frontend/pages/edit_despesa.dart';
import 'package:frontend/pages/edit_receita.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/inserir_despesas.dart';
import 'pages/inserir_receitas.dart';
import 'pages/receitas_detalhadas.dart';
import 'pages/despesas_detalhadas.dart';

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
        primarySwatch: Colors.blue, // azul padrão do Flutter
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2F80ED), // seu azulzinho preferido
          foregroundColor: Colors.white, // cor dos textos e ícones no AppBar
          elevation: 4,
        ),
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
        '/edit-despesa': (context) => const EditDespesaPage(),
        '/edit-receita': (context) => const EditReceitaPage(),
      },
    );
  }
}
