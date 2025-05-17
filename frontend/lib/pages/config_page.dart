import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ConfiguracoesPage extends StatefulWidget {
  final Map<String, dynamic> dadosUsuario;

  const ConfiguracoesPage({super.key, required this.dadosUsuario});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  String _estadosUrl = '';
  Map<int, String> estadosMap = {};

  @override
  void initState() {
    super.initState();
    _setupApiUrl();
  }

  Future<bool> isRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  Future<void> _setupApiUrl() async {
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    _estadosUrl = '$baseUrl/estados';
    await _carregarEstados();
  }

  Future<void> _carregarEstados() async {
    try {
      final response = await http.get(Uri.parse(_estadosUrl));
      if (response.statusCode == 200) {
        final String bodyUtf8 = utf8.decode(response.bodyBytes);
        final List<dynamic> estados = jsonDecode(bodyUtf8);
        setState(() {
          estadosMap = {
            for (var estado in estados) estado['id']: estado['nome']
          };
        });
      } else {
        print('Erro ao carregar estados: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar estados: $e');
    }
  }

  String formatarData(String? data) {
    if (data == null) return 'Não informado';
    try {
      final dataParse = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy').format(dataParse);
    } catch (e) {
      return 'Formato inválido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final endereco = widget.dadosUsuario['endereco'] ?? {};
    final idEstado = endereco['id_estado'];
    final nomeEstado = estadosMap[idEstado] ?? 'Carregando...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Dados Pessoais'),
          _buildInfoCard(Icons.person, 'Nome Completo',
              '${widget.dadosUsuario['nome']} ${widget.dadosUsuario['sobrenome']}'),
          _buildInfoCard(Icons.email, 'E-mail', widget.dadosUsuario['email']),
          _buildInfoCard(
            Icons.cake,
            'Data de Nascimento',
            formatarData(widget.dadosUsuario['data_nascimento']),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Endereço'),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnderecoRow(Icons.map, 'CEP', endereco['cep']),
                  _buildEnderecoRow(Icons.flag, 'Estado', nomeEstado),
                  _buildEnderecoRow(Icons.home, 'Rua', endereco['rua']),
                  _buildEnderecoRow(
                      Icons.numbers, 'Número', endereco['numero']),
                  _buildEnderecoRow(
                      Icons.location_city, 'Bairro', endereco['bairro']),
                  _buildEnderecoRow(
                      Icons.place, 'Complemento', endereco['complemento']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String? value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(value ?? 'Não informado'),
      ),
    );
  }

  Widget _buildEnderecoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${value ?? 'Não informado'}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
