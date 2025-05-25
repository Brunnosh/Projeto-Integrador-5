import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Map<String, dynamic>?> _obterDetalhesReceita(int idReceita) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/unica-receita/$idReceita?id_login=$userId';

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

  Future<void> _deletarReceita(int idReceita) async {
    final receita = await _obterDetalhesReceita(idReceita);

    if (receita == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar detalhes da receita')),
      );
      return;
    }

    final bool recorrente = receita['recorrencia'] ?? false;

    if (!recorrente) {
      await _confirmarEDeletar(idReceita);
      return;
    }

    final escolha = await showDialog<String>(
      context: context,
      builder: (context) => const RecorrenciaDeleteDialog(),
    );
    if (escolha == 'total') {
      await _confirmarEDeletar(idReceita);
    } else if (escolha == 'parcial') {
      await _encerrarRecorrencia(idReceita);
    }
  }

  Future<void> _confirmarEDeletar(int idReceita) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/delete-receita/$idReceita';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita excluída com sucesso')),
        );
        _loadReceitas();
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

  Future<void> _encerrarRecorrencia(int idReceita) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final idLogin = prefs.getString('userId');

    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

    final getUrl = '$baseUrl/unica-receita/$idReceita?id_login=$idLogin';
    final putUrl = '$baseUrl/fim-recorrencia-receita/$idReceita';

    try {
      // Buscar a receita para pegar a data_recebimento
      final getResponse = await http.get(
        Uri.parse(getUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) {
        throw Exception("Erro ao buscar receita para edição");
      }

      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
      final dataRecebimento = DateTime.parse(data["data_recebimento"]);

      final int selectedMonthNum = monthToNumber[selectedMonth]!;
      final int selectedYearNum = int.parse(selectedYear);

      int anoFim =
          selectedMonthNum == 1 ? selectedYearNum - 1 : selectedYearNum;
      int mesFim = selectedMonthNum == 1 ? 12 : selectedMonthNum - 1;

      int diaFim = dataRecebimento.day;

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
        _loadReceitas();
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

  Widget _buildReceitaTile(Map<String, dynamic> receita) {
    final descricao = receita['descricao'] ?? '';
    final valor = receita['valor'] ?? 0.0;
    final recorrente = receita['recorrencia'] ?? true;
    final idReceita = receita['id'];

    final mes = monthToNumber[selectedMonth]!;

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorFormatado = currencyFormat.format(valor);

    final original = receita['data_recebimento'] ?? '';
    String dataRecebimento;

    String fimRecorrenciaFormatada = 'Indeterminado';
    if (receita['fim_recorrencia'] != null) {
      try {
        final parsedFim = DateTime.parse(receita['fim_recorrencia']);
        fimRecorrenciaFormatada =
            '${parsedFim.day.toString().padLeft(2, '0')}/${parsedFim.month.toString().padLeft(2, '0')}/${parsedFim.year}';
      } catch (_) {
        fimRecorrenciaFormatada = receita['fim_recorrencia'];
      }
    }

    try {
      final parsedDate = DateTime.parse(original);
      final dia = parsedDate.day;

      if (recorrente) {
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
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
                    color: Colors.green,
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
                  'Recebido em: $dataRecebimento',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Recorrente: ${recorrente ? "Sim" : "Não"}'),
            if (recorrente)
              Text('Fim da recorrência: $fimRecorrenciaFormatada'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar Receita',
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      '/edit-receita',
                      arguments: {
                        'id': idReceita,
                        'mes': mes,
                        'ano': int.parse(selectedYear),
                      },
                    );
                    _loadReceitas();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Excluir Receita',
                  onPressed: () {
                    _deletarReceita(idReceita);
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
          Text('Receita recorrente'),
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
