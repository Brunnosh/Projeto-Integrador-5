import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyWallet App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HelloScreen(),
    );
  }
}

class HelloScreen extends StatefulWidget {
  const HelloScreen({super.key});

  @override
  State<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  String message = "Carregando...";

  @override
  void initState() {
    super.initState();
    fetchHello();
  }

  Future<void> fetchHello() async {
    try {
      // 10.0.2.2 é o IP que representa "localhost" dentro do emulador Android
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/hello'));
      if (response.statusCode == 200) {
        setState(() {
          message = json.decode(response.body)['message'];
        });
      } else {
        setState(() {
          message = "Erro da API: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        message = "Erro de conexão: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MyWallet")),
      body: Center(
        child: Text(message, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}