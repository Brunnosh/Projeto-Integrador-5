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
  late String selectedMonth, selectedYear;
  late List<String> years;
  double saldo = 0.0;
  double receitas = 0.0;
  double despesas = 0.0;
  String userEmail = '';
  String _userApiUrl = '';
  String _receitasUrl = '';
  String _despesasUrl = '';

  final Map<String, int> monthToNumber = {
    'Janeiro': 1,
    'Fevereiro': 2,
    'Março': 3,
    'Abril': 4,
    'Maio': 5,
    'Junho': 6,
    'Julho': 7,
    'Agosto': 8,
    'Setembro': 9,
    'Outubro': 10,
    'Novembro': 11,
    'Dezembro': 12,
  };

  @override
  void initState() {
    super.initState();

    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;
    years = List.generate(11, (index) => (currentYear - 5 + index).toString());
    selectedYear = currentYear.toString();
    selectedMonth = monthToNumber.entries
        .firstWhere((entry) => entry.value == currentMonth)
        .key;
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
    setState(() {
      _userApiUrl = '$baseUrl/me';
      _receitasUrl = '$baseUrl/total-receitas';
      _despesasUrl = '$baseUrl/total-despesas';
    });
    await _getUserEmail();
    _loadData();
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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');
    final mes = monthToNumber[selectedMonth];

    if (token == null) return;

    Future<Map<String, double>> _fetchData(String url) async {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'total': data['total'] ?? 0.0};
      }
      return {'total': 0.0};
    }

    try {
      final receitasData = await _fetchData(
          '$_receitasUrl?id_login=$userId&mes=$mes&ano=$selectedYear');

      final despesasData = await _fetchData(
          '$_despesasUrl?id_login=$userId&mes=$mes&ano=$selectedYear');

      setState(() {
        receitas = receitasData['total']!;
        despesas = despesasData['total']!;
        saldo = receitas - despesas;
      });
    } catch (e) {
      setState(() {
        receitas = 0.0;
        despesas = 0.0;
        saldo = 0.0;
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
            onTap: () async {
              Navigator.pop(context);
              await Navigator.pushNamed(context, '/inserir-receitas');
              _loadData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text('Adicionar Despesa'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.pushNamed(context, '/inserir-despesas');
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    String title,
    double value,
    Color color,
    IconData icon, {
    VoidCallback? onViewPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${value.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (onViewPressed != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.visibility),
                color: Colors.blue[600],
                tooltip: 'Ver detalhes',
                onPressed: onViewPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Expanded(
      child: DropdownButtonFormField<T>(
        value: value as T?,
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemBuilder(item)),
                ))
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
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
                _buildDropdown<String>(
                  label: 'Mês',
                  value: selectedMonth,
                  items: monthToNumber.keys.toList(),
                  onChanged: (value) {
                    setState(() => selectedMonth = value!);
                    _loadData();
                  },
                  itemBuilder: (item) => item,
                ),
                const SizedBox(width: 16),
                _buildDropdown<String>(
                  label: 'Ano',
                  value: selectedYear,
                  items: years,
                  onChanged: (value) {
                    setState(() => selectedYear = value!);
                    _loadData();
                  },
                  itemBuilder: (item) => item,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCard('Saldo Atual', saldo, Colors.blue,
                Icons.account_balance_wallet),
            _buildCard(
              'Receitas',
              receitas,
              Colors.green,
              Icons.arrow_downward,
              onViewPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');
                final mes = monthToNumber[selectedMonth];

                await Navigator.pushNamed(
                  context,
                  '/receitas-detalhadas',
                  arguments: {
                    'id_login': userId,
                    'mes': mes,
                    'ano': selectedYear,
                  },
                );
                _loadData();
              },
            ),
            _buildCard(
              'Despesas',
              despesas,
              Colors.red,
              Icons.arrow_upward,
              onViewPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');
                final mes = monthToNumber[selectedMonth];

                await Navigator.pushNamed(
                  context,
                  '/despesas-detalhadas',
                  arguments: {
                    'id_login': userId,
                    'mes': mes,
                    'ano': selectedYear,
                  },
                );
                _loadData();
              },
            ),
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
