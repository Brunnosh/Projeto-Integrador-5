import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late String selectedMonth, selectedYear;
  late List<String> years;
  late int? userId;
  List<Map<String, dynamic>> despesasPorDia = [];
  String apiUrl = '';

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
    final now = DateTime.now();
    selectedMonth =
        monthToNumber.entries.firstWhere((e) => e.value == now.month).key;
    selectedYear = now.year.toString();
    years = List.generate(11, (i) => (now.year - 5 + i).toString());
    _setupApi();
  }

  Future<void> _setupApi() async {
    final isEmulator = await _isRunningOnEmulator();
    final prefs = await SharedPreferences.getInstance();
    userId = int.tryParse(prefs.getString('userId') ?? '');
    if (userId == null) return;
    apiUrl = isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    _loadDespesasPorDia();
  }

  Future<bool> _isRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return !info.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return !info.isPhysicalDevice;
    }
    return false;
  }

  Future<void> _loadDespesasPorDia() async {
    if (userId == null) return;

    final mes = monthToNumber[selectedMonth];
    final url = Uri.parse('$apiUrl/contagem-despesas-por-dia-vencimento'
        '?id_login=$userId&mes=$mes&ano=$selectedYear');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          despesasPorDia = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {
      setState(() {
        despesasPorDia = [];
      });
    }
  }

  double _getMaxY() {
    if (despesasPorDia.isEmpty) return 3;

    final max = despesasPorDia
        .map((e) => e['quantidade'] as num)
        .reduce((a, b) => a > b ? a : b);

    return (max < 3 ? 3 : (max.ceilToDouble() + 1));
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
        value: value as T,
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemBuilder(item)),
                ))
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (despesasPorDia.isEmpty) {
      return const Center(child: Text('Nenhuma despesa encontrada.'));
    }

    return SizedBox(
      height: 240, // Ajuste a altura do gráfico aqui
      child: BarChart(
        BarChartData(
          maxY: _getMaxY(), // Usa a função auxiliar
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  if (value % 1 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const SizedBox.shrink(); // oculta decimais
                },
              ),
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Qtde. de Contas'),
              ),
              axisNameSize: 16,
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              axisNameWidget: const Text('Dia do Vencimento'),
              axisNameSize: 16,
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          barGroups: despesasPorDia.map((dado) {
            final dia = dado['dia'] as int;
            final qtd = (dado['quantidade'] as num).toDouble();
            return BarChartGroupData(
              x: dia,
              barRods: [
                BarChartRodData(
                  toY: qtd,
                  color: Colors.deepPurpleAccent,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros
            Row(
              children: [
                _buildDropdown<String>(
                  label: 'Mês',
                  value: selectedMonth,
                  items: monthToNumber.keys.toList(),
                  onChanged: (value) {
                    setState(() => selectedMonth = value!);
                    _loadDespesasPorDia();
                  },
                  itemBuilder: (item) => item,
                ),
                const SizedBox(width: 12),
                _buildDropdown<String>(
                  label: 'Ano',
                  value: selectedYear,
                  items: years,
                  onChanged: (value) {
                    setState(() => selectedYear = value!);
                    _loadDespesasPorDia();
                  },
                  itemBuilder: (item) => item,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Título do gráfico
            const Text(
              'Dias de Vencimento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Cartão do gráfico
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBarChart(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
