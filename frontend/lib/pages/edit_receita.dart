import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/environment.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/pages/config_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _receitasUrl = '';

class EditReceitaPage extends StatefulWidget {
  const EditReceitaPage({super.key});

  @override
  State<EditReceitaPage> createState() => _EditReceitaPageState();
}

class _EditReceitaPageState extends State<EditReceitaPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataRecebimentoController = TextEditingController();
  final _fimRecorrenciaController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _fimRecorrencia;
  bool _recorrente = false;
  int? _receitaId;
  int? _selectedMes;
  int? _selectedAno;

  DateTime _parseDate(String input) {
    return DateFormat('dd/MM/yyyy').parseStrict(input);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _receitaId = args['id'];
        _selectedMes = args['mes'];
        _selectedAno = args['ano'];
      }
      _setupApiUrl();
    });
  }

  Future<void> _setupApiUrl() async {
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    setState(() {
      _receitasUrl = '$baseUrl/update-receita';
    });

    await _carregarReceita();
  }

  Future<void> _carregarReceita() async {
    if (_receitaId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final idLogin = prefs.getString('userId');
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/unica-receita/$_receitaId?id_login=$idLogin';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _descricaoController.text = data['descricao'] ?? '';

          final valor = data['valor'];
          _valorController.text = valor != null
              ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(valor)
              : '';

          _selectedDate = DateTime.tryParse(data['data_recebimento'] ?? '');
          _dataRecebimentoController.text =
              _selectedDate != null ? _formatDate(_selectedDate!) : '';

          _recorrente = data['recorrencia'] ?? false;
          if (data['fim_recorrencia'] != null) {
            _fimRecorrencia = DateTime.tryParse(data['fim_recorrencia']);
            _fimRecorrenciaController.text =
                _fimRecorrencia != null ? _formatDate(_fimRecorrencia!) : '';
          } else {
            _fimRecorrencia = null;
            _fimRecorrenciaController.clear();
          }
        });
      } else {
        _showSnackbar('Erro ao carregar receita');
      }
    } catch (e) {
      _showSnackbar('Erro ao carregar: $e');
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

  Future<void> atualizarReceita() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Preencha todos os campos corretamente.");
      return;
    }

    try {
      _selectedDate = _parseDate(_dataRecebimentoController.text);
      if (_recorrente) {
        if (_fimRecorrenciaController.text.trim().isEmpty) {
          _fimRecorrencia = null;
        } else {
          _fimRecorrencia = _parseDate(_fimRecorrenciaController.text);

          if (_fimRecorrencia!.isBefore(_selectedDate!) ||
              _fimRecorrencia!.isAtSameMomentAs(_selectedDate!)) {
            _showSnackbar(
                "A data de fim da recorrência deve ser posterior à data de recebimento.");
            return;
          }
        }
      }
    } catch (_) {
      _showSnackbar("Datas inválidas.");
      return;
    }

    if (_receitaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID da receita não está definido')),
      );
      return;
    }

    final receita = await _obterDetalhesReceita(_receitaId!);

    if (receita == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar detalhes da receita')),
      );
      return;
    }

    final bool recorrente = receita['recorrencia'] ?? false;

    if (!recorrente) {
      await _confirmarEEditar();
      return;
    }

    final escolha = await showDialog<String>(
      context: context,
      builder: (context) => const RecorrenciaDeleteDialog(),
    );
    if (escolha == 'total') {
      await _confirmarEEditar();
    } else if (escolha == 'parcial') {
      await _encerrarRecorrencia(_receitaId!);
    }
  }

  Future<void> _confirmarEEditar() async {
    final url = '$_receitasUrl/$_receitaId';

    final requestBody = {
      'descricao': _descricaoController.text,
      'valor': double.tryParse(
            _valorController.text
                .replaceAll(RegExp(r'[^\d,]'), '')
                .replaceAll(',', '.'),
          ) ??
          0.0,
      'data_recebimento': _selectedDate!.toIso8601String().split('T')[0],
      'recorrencia': _recorrente
    };

    if (_fimRecorrencia != null) {
      requestBody['fim_recorrencia'] =
          _fimRecorrencia!.toIso8601String().split('T')[0];
    }

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _showSnackbar(responseData['mensagem']);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showSnackbar('Erro ao editar: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Erro ao editar: $e');
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
      final getResponse = await http.get(
        Uri.parse(getUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) {
        throw Exception("Erro ao buscar receita para edição");
      }

      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
      final dataRecebimento = DateTime.parse(data["data_recebimento"]);

      int anoFim = _selectedMes! == 1 ? _selectedAno! - 1 : _selectedAno!;
      int mesFim = _selectedMes! == 1 ? 12 : _selectedMes! - 1;

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
        final insertUrl = '$baseUrl/inserir-receita';

        _selectedDate = _parseDate(_dataRecebimentoController.text);

        final novoBody = {
          "id_login": idLogin,
          "descricao": _descricaoController.text,
          "valor": double.tryParse(
                _valorController.text
                    .replaceAll(RegExp(r'[^\d,]'), '')
                    .replaceAll(',', '.'),
              ) ??
              0.0,
          "data_recebimento": _selectedDate!.toIso8601String().split('T')[0],
          "recorrencia": _recorrente,
          "fim_recorrencia": _fimRecorrencia != null
              ? _fimRecorrencia!.toIso8601String().split('T')[0]
              : null,
        };

        final insertResponse = await http.post(
          Uri.parse(insertUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(novoBody),
        );

        if (insertResponse.statusCode == 200) {
          final responseData = jsonDecode(insertResponse.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['mensagem'])),
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erro ao inserir nova receita: ${insertResponse.body}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erro ao encerrar recorrência: ${putResponse.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  Widget _buildRecorrenciaSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SwitchListTile(
              title: Row(
                children: const [
                  Icon(Icons.repeat, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Receita Recorrente'),
                ],
              ),
              value: _recorrente,
              onChanged: (value) {
                setState(() {
                  _recorrente = value;
                });
              },
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_recorrente) ...[
            const SizedBox(height: 12),
            _buildDateField(
                'Fim da Recorrência (opcional)', _fimRecorrenciaController,
                obrigatorio: false),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final currentDate = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (value) =>
          value == null || value.isEmpty ? 'Campo obrigatório' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller,
      {bool obrigatorio = true}) {
    return TextFormField(
      controller: controller,
      readOnly: false,
      inputFormatters: [DateInputFormatter()],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(controller),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (obrigatorio && (value == null || value.isEmpty)) {
          return 'Campo obrigatório';
        }
        if (value != null && value.isNotEmpty) {
          try {
            _parseDate(value);
          } catch (_) {
            return 'Data inválida (ex: 10/04/2025)';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Receita')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Descrição *', _descricaoController),
              const SizedBox(height: 12),
              _buildDateField(
                  'Primeiro Recebimento *', _dataRecebimentoController),
              const SizedBox(height: 12),
              _buildTextField(
                'Valor *',
                _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecorrenciaSwitch(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: atualizarReceita,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse o número como inteiro (sem casas decimais)
    int value = int.parse(digitsOnly);

    // Divide por 100 para colocar as duas últimas casas como decimais
    double doubleValue = value / 100;

    // Formata para moeda brasileira
    final newText = currencyFormat.format(doubleValue);

    // Mantém o cursor no fim do texto formatado
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
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
              text: 'Deseja que as alterações sejam salvas:\n\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: '• Apenas para os registros deste mês em diante.\n'),
            TextSpan(
                text:
                    '• Para todos os registros, inclusive de meses anteriores.'),
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
                child: const Text('Alterar todos'),
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
