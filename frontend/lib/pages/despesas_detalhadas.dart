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

  Future<Map<String, dynamic>?> _obterDetalhesDespesa(int idDespesa) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/unica-despesa/$idDespesa?id_login=$userId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _deletarDespesa(int idDespesa) async {
    final despesa = await _obterDetalhesDespesa(idDespesa);

    if (despesa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar detalhes da despesa')),
      );
      return;
    }

    final bool recorrente = despesa['recorrencia'] ?? false;

    if (!recorrente) {
      await _confirmarEDeletar(idDespesa);
      return;
    }

    final escolha = await showDialog<String>(
      context: context,
      builder: (context) => const RecorrenciaDeleteDialog(),
    );
    if (escolha == 'total') {
      await _confirmarEDeletar(idDespesa);
    } else if (escolha == 'parcial') {
      await _encerrarRecorrencia(idDespesa);
    }
  }

  Future<void> _confirmarEDeletar(int idDespesa) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/delete-despesa/$idDespesa';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Despesa excluída com sucesso')),
        );
        _loadDespesas();
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

  Future<void> _encerrarRecorrencia(int idDespesa) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final idLogin = prefs.getString('userId');

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

    final getUrl = '$baseUrl/unica-despesa/$idDespesa?id_login=$idLogin';
    final putUrl = '$baseUrl/fim-recorrencia-despesa/$idDespesa';

    try {
      final getResponse = await http.get(
        Uri.parse(getUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) {
        throw Exception("Erro ao buscar despesa para edição");
      }

      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
      final dataVencimento = DateTime.parse(data["data_vencimento"]);

      final int selectedMonthNum = monthToNumber[selectedMonth]!;
      final int selectedYearNum = int.parse(selectedYear);

      int anoFim =
          selectedMonthNum == 1 ? selectedYearNum - 1 : selectedYearNum;
      int mesFim = selectedMonthNum == 1 ? 12 : selectedMonthNum - 1;

      int diaFim = dataVencimento.day;

      final ultimoDiaMes = DateTime(anoFim, mesFim + 1, 0).day;
      if (diaFim > ultimoDiaMes) diaFim = ultimoDiaMes;

      final fimRecorrencia = DateTime(anoFim, mesFim, diaFim);

      final body = {
        "fim_recorrencia": fimRecorrencia.toIso8601String(),
      };

      final putResponse = await http.put(
        Uri.parse(putUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (putResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorrência encerrada com sucesso')),
        );
        _loadDespesas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${putResponse.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
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
    final idDespesa = despesa['id'];

    final mes = monthToNumber[selectedMonth]!;

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorFormatado = currencyFormat.format(valor);

    final original = despesa['data_vencimento'] ?? '';
    String dataVencimento;

    String fimRecorrenciaFormatada = 'Indeterminado';
    if (despesa['fim_recorrencia'] != null) {
      try {
        final parsedFim = DateTime.parse(despesa['fim_recorrencia']);
        fimRecorrenciaFormatada =
            '${parsedFim.day.toString().padLeft(2, '0')}/${parsedFim.month.toString().padLeft(2, '0')}/${parsedFim.year}';
      } catch (_) {
        fimRecorrenciaFormatada = despesa['fim_recorrencia'];
      }
    }

    try {
      final parsedDate = DateTime.parse(original);
      final dia = parsedDate.day;

      if (recorrente) {
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
            if (recorrente)
              Text('Fim da recorrência: $fimRecorrenciaFormatada'),
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
                      arguments: {
                        'id': idDespesa,
                        'mes': mes,
                        'ano': int.parse(selectedYear),
                      },
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
                  ? const Center(child: Text('Nenhuma despesa encontrada.'))
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

class RecorrenciaDeleteDialog extends StatelessWidget {
  const RecorrenciaDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('Despesa recorrente'),
        ],
      ),
      content: const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Deseja excluir:\n\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: '• Apenas os registros deste mês em diante.\n'),
            TextSpan(text: '• Todos os registros, inclusive meses anteriores?'),
          ],
        ),
      ),
      actions: [
        Center(
          child: Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'parcial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // fundo azul
                  foregroundColor: Colors.white, // texto branco
                ),
                child: const Text('Deste mês em diante'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'total'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Excluir todos'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
