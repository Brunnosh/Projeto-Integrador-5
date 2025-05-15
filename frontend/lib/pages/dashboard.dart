import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  final int idLogin;
  const DashboardScreen({Key? key, required this.idLogin}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String selectedMonth, selectedYear;
  late List<String> years;

  List<BarChartGroupData> barGroups = [];
  List<PieChartSectionData> pieSections = [];

  String _diaVencimentoUrl = '';
  String _despesasCategoriaUrl = '';

  final List<Color> bluePalette = [
    Color(0xFF56CCF2), // azul claro
    Color(0xFF2F80ED), // azul médio
    Color(0xFFBB6BD9), // lilás
    Color(0xFF9B51E0), // roxo claro
    Color(0xFF6FCF97), // verde menta
    Color(0xFF219653), // verde escuro
  ];
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
    _setupApi();
  }

  void _setupApi() async {
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    setState(() {
      _diaVencimentoUrl = '$baseUrl/contagem-despesas-por-dia-vencimento';
      _despesasCategoriaUrl = '$baseUrl/contagem-despesas-por-categoria';
    });
    _loadDespesasPorDiaVencimento();
    _loadDespesasPorCategoria();
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

  Future<void> _loadDespesasPorDiaVencimento() async {
    final mes = monthToNumber[selectedMonth];
    final url = Uri.parse(
        '$_diaVencimentoUrl?id_login=${widget.idLogin}&mes=$mes&ano=$selectedYear');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

      setState(() {
        barGroups = data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return BarChartGroupData(
            x: item['dia'],
            barRods: [
              BarChartRodData(
                toY: item['quantidade'].toDouble(),
                color: bluePalette[index % bluePalette.length], // aqui
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList();
      });
    }
  }

  Future<void> _loadDespesasPorCategoria() async {
    final url = Uri.parse(
        '$_despesasCategoriaUrl?id_login=${widget.idLogin}&mes=${monthToNumber[selectedMonth]}&ano=$selectedYear');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        pieSections = data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final colors = bluePalette;
          final total = data.fold<double>(0, (sum, e) => sum + e['quantidade']);
          final percentual = (item['quantidade'] / total) * 100;

          return PieChartSectionData(
            value: item['quantidade'].toDouble(),
            title: '',
            color: colors[index % colors.length],
            radius: 60,
            badgeWidget: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['categoria'],
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${percentual.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            badgePositionPercentageOffset: 1.6,
            showTitle: false,
          );
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildDropdown<String>(
                      label: 'Mês',
                      value: selectedMonth,
                      items: monthToNumber.keys.toList(),
                      onChanged: (value) {
                        setState(() => selectedMonth = value!);
                        _setupApi();
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
                        _setupApi();
                      },
                      itemBuilder: (item) => item,
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Despesas por Dia de Vencimento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBarChart(),
            const SizedBox(height: 24),
            const Text(
              'Despesas por Categoria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPieChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 240,
      child: barGroups.isEmpty
          ? const Center(child: Text('Nenhum dado disponível'))
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Text('${value.toInt()}'),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Text('${value.toInt()}'),
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
              swapAnimationDuration: const Duration(milliseconds: 500),
              swapAnimationCurve: Curves.easeInOut,
            ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 220,
      child: pieSections.isEmpty
          ? const Center(child: Text('Nenhum dado disponível'))
          : PieChart(
              PieChartData(
                sections: pieSections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
              swapAnimationDuration: const Duration(milliseconds: 500),
              swapAnimationCurve: Curves.easeInOut,
            ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Expanded(
      child: DropdownButtonFormField<T>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(itemBuilder(item)),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
