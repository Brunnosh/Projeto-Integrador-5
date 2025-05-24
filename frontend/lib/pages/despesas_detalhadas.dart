import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DespesasDetalhadasPage extends StatefulWidget {
  const DespesasDetalhadasPage({super.key});

  @override
  State<DespesasDetalhadasPage> createState() => _DespesasDetalhadasPageState();
}

class _DespesasDetalhadasPageState extends State<DespesasDetalhadasPage> {
  late String selectedMonth, selectedYear;
  late List<String> years;

  int? _idCategoriaSelecionada;

  List<Map<String, dynamic>> despesas = [];
  List<Map<String, dynamic>> _categorias = [];

  String _despesasUrl = '';
  String _categoriasUrl = '';

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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _nomeCategoriaPorId(int? idCategoria) {
    final categoria = _categorias.firstWhere(
      (cat) => cat['id'] == idCategoria,
      orElse: () => {'nome': 'Categoria não encontrada'},
    );
    return categoria['nome'];
  }

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
      _despesasUrl = '$baseUrl/detalhes-despesas';
      _categoriasUrl = '$baseUrl/categoria';
    });
    await _loadDespesas();
    await _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    try {
      final response = await http.get(Uri.parse(_categoriasUrl));
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _categorias = data.cast<Map<String, dynamic>>();
          if (_categorias.isNotEmpty) {
            _idCategoriaSelecionada = _categorias[0]['id'];
          }
        });
      } else {
        _showSnackbar('Erro ao carregar categorias');
      }
    } catch (e) {
      _showSnackbar('Erro: $e');
    }
  }

  Future<void> _loadDespesas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');
    final mes = monthToNumber[selectedMonth];

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_despesasUrl?id_login=$userId&mes=$mes&ano=$selectedYear'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          despesas = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          despesas = [];
        });
      }
    } catch (e) {
      setState(() {
        despesas = [];
      });
    }
  }

  Future<void> _deletarDespesa(int idDespesa) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');

    print('Deletando despesa $idDespesa com id_login: $userId');

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/delete-despesa/$idDespesa?id_login=$userId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Despesa excluída com sucesso')),
        );
        _loadDespesas(); // recarrega a lista
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir despesa')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao excluir despesa')),
      );
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

  Widget _buildDespesaTile(Map<String, dynamic> despesa) {
    final descricao = despesa['descricao'] ?? '';
    final valor = despesa['valor'] ?? 0.0;
    final categoria = despesa['id_categoria'] ?? '';
    final recorrente = despesa['recorrencia'] ?? false;
    final fimRecorrencia = despesa['fim_recorrencia'] ?? 'Indeterminado';
    final idDespesa = despesa['id'];

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorFormatado = currencyFormat.format(valor);

    final original = despesa['data_vencimento'] ?? '';
    String dataVencimento;

    try {
      final parsedDate = DateTime.parse(original);
      final dia = parsedDate.day;

      if (recorrente) {
        final mes = monthToNumber[selectedMonth]!;
        final ano = int.parse(selectedYear);
        final novaData = DateTime(ano, mes, dia);
        dataVencimento =
            '${novaData.day.toString().padLeft(2, '0')}/${novaData.month.toString().padLeft(2, '0')}/${novaData.year}';
      } else {
        dataVencimento =
            '${dia.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
      }
    } catch (_) {
      dataVencimento = original;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    descricao,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  valorFormatado,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Pago em: $dataVencimento',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Recorrente: ${recorrente ? "Sim" : "Não"}'),
            if (recorrente) Text('Fim da recorrência: $fimRecorrencia'),
            const SizedBox(height: 4),
            Text('Categoria: ${_nomeCategoriaPorId(categoria)}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar Despesa',
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      '/edit-despesa',
                      arguments: {'id': idDespesa},
                    );
                    _loadDespesas();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Excluir Despesa',
                  onPressed: () {
                    _deletarDespesa(idDespesa);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Despesas Detalhadas')),
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
                    _loadDespesas();
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
                    _loadDespesas();
                  },
                  itemBuilder: (item) => item,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: despesas.isEmpty
                  ? const Center(child: Text('Nenhuma receita encontrada.'))
                  : ListView.builder(
                      itemCount: despesas.length,
                      itemBuilder: (context, index) {
                        return _buildDespesaTile(despesas[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
