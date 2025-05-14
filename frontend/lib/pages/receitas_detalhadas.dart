import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ReceitasDetalhadasPage extends StatefulWidget {
  const ReceitasDetalhadasPage({super.key});

  @override
  State<ReceitasDetalhadasPage> createState() => _ReceitasDetalhadasPageState();
}

class _ReceitasDetalhadasPageState extends State<ReceitasDetalhadasPage> {
  late String selectedMonth, selectedYear;
  late List<String> years;
  List<Map<String, dynamic>> receitas = [];
  String _receitasUrl = '';

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
      _receitasUrl = '$baseUrl/detalhes-receitas';
    });
    _loadReceitas();
  }

  Future<void> _loadReceitas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');
    final mes = monthToNumber[selectedMonth];

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_receitasUrl?id_login=$userId&mes=$mes&ano=$selectedYear'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          receitas = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          receitas = [];
        });
      }
    } catch (e) {
      setState(() {
        receitas = [];
      });
    }
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Future<void> _deletarReceita(int idreceita) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');

    print('Deletando receita $idreceita com id_login: $userId');

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/receita/$idreceita?id_login=$userId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita excluída com sucesso')),
        );
        _loadReceitas(); // recarrega a lista
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir receita')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao excluir receita')),
      );
    }
  }

  Widget _buildReceitaTile(Map<String, dynamic> receita) {
    final descricao = receita['descricao'] ?? '';
    final valor = receita['valor'] ?? 0.0;
    final recorrente = receita['recorrencia'] ?? true;
    final fimRecorrencia = receita['fim_recorrencia'] ?? '-';
    final idReceita = receita['id'];

    final original = receita['data_recebimento'] ?? '';
    String dataRecebimento;
    try {
      final parsedDate = DateTime.parse(original);
      final dia = parsedDate.day;

      if (recorrente) {
        final mes = monthToNumber[selectedMonth]!;
        final ano = int.parse(selectedYear);
        final novaData = DateTime(ano, mes, dia);
        dataRecebimento =
            '${novaData.day.toString().padLeft(2, '0')}/${novaData.month.toString().padLeft(2, '0')}/${novaData.year}';
      } else {
        dataRecebimento =
            '${dia.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
      }
    } catch (_) {
      dataRecebimento = original;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.attach_money, color: Colors.green),
        title: Text(descricao),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recebido em: $dataRecebimento'),
            Text('Recorrente: ${recorrente ? "Sim" : "Não"}'),
            if (recorrente) Text('Fim da recorrência: $fimRecorrencia'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${valor.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Editar receita',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit-receita',
                  arguments: {'id': idReceita},
                );
                _loadReceitas();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Excluir receita',
              onPressed: () {
                _deletarReceita(idReceita);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receitas Detalhadas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildDropdown<String>(
                  label: 'Mês',
                  value: selectedMonth,
                  items: monthToNumber.keys.toList(),
                  onChanged: (value) {
                    setState(() => selectedMonth = value!);
                    _loadReceitas();
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
                    _loadReceitas();
                  },
                  itemBuilder: (item) => item,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: receitas.isEmpty
                  ? const Center(child: Text('Nenhuma receita encontrada.'))
                  : ListView.builder(
                      itemCount: receitas.length,
                      itemBuilder: (context, index) {
                        return _buildReceitaTile(receitas[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
