import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedMonth = 'Maio';
  late String selectedYear;

  final List<String> months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  late List<String> years;

  double saldo = 1500.0;
  double receitas = 3000.0;
  double despesas = 1500.0;

  String userEmail = '';
  String _userApiUrl = '';

  @override
  void initState() {
    super.initState();

    final currentYear = DateTime.now().year;
    years = List.generate(11, (index) => (currentYear - 5 + index).toString());
    selectedYear = currentYear.toString();

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
    setState(() {
      _userApiUrl =
          isEmulator ? 'http://10.0.2.2:8000/me' : 'http://localhost:8000/me';
    });
    _getUserEmail();
  }

  Future<void> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        userEmail = 'Token não encontrado';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_userApiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userEmail = data['email'];
          prefs.setString('userId', data['id'].toString());
        });
      } else {
        setState(() {
          userEmail = 'Erro ao obter e-mail';
        });
      }
    } catch (e) {
      setState(() {
        userEmail = 'Erro de conexão';
      });
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Adicionar Receita'),
            onTap: () {
              Navigator.pushNamed(context, '/inserir-receitas');
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text('Adicionar Despesa'),
            onTap: () {
              Navigator.pushNamed(context, '/inserir-despesas');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, double value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyFinance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Bem-vindo, $userEmail',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: selectedMonth,
                      items: months
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedMonth = value!);
                      },
                      isExpanded: true,
                      icon:
                          const Icon(Icons.arrow_drop_down, color: Colors.blue),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Mês',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: selectedYear,
                      items: years
                          .map(
                              (y) => DropdownMenuItem(value: y, child: Text(y)))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedYear = value!);
                      },
                      isExpanded: true,
                      icon:
                          const Icon(Icons.arrow_drop_down, color: Colors.blue),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Ano',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCard('Saldo Atual', saldo, Colors.blue,
                Icons.account_balance_wallet),
            _buildCard(
                'Receitas', receitas, Colors.green, Icons.arrow_downward),
            _buildCard('Despesas', despesas, Colors.red, Icons.arrow_upward),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.pie_chart),
              label: const Text('Ver Dashboard'),
              onPressed: () {
                // Navegar para tela de dashboard
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }
}
