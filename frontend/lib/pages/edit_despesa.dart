import 'dart:convert';
import 'package:frontend/pages/despesas_detalhadas.dart';
import 'package:intl/intl.dart';
import '../utils/environment.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String _despesasUrl = '';

class EditDespesaPage extends StatefulWidget {
  const EditDespesaPage({super.key});

  @override
  State<EditDespesaPage> createState() => _EditDespesaPageState();
}

class _EditDespesaPageState extends State<EditDespesaPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataVencimentoController = TextEditingController();
  final _fimRecorrenciaController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _fimRecorrencia;
  int? _idCategoriaSelecionada;
  bool _recorrente = false;
  int? _despesaId;
  int? _selectedMes;
  int? _selectedAno;
  String _categoriasUrl = '';
  List<Map<String, dynamic>> _categorias = [];

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
        _despesaId = args['id'];
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
      _despesasUrl = '$baseUrl/update-despesa';
      _categoriasUrl = '$baseUrl/categoria';
    });
    await _carregarCategorias();
    await _carregarDespesa();
  }

  Future<void> _carregarCategorias() async {
    try {
      final response = await http.get(Uri.parse(_categoriasUrl));
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _categorias = data.cast<Map<String, dynamic>>();
          if (_categorias.isNotEmpty && _idCategoriaSelecionada == null) {
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

  Future<void> _carregarDespesa() async {
    if (_despesaId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final idLogin = prefs.getString('userId');
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = '$baseUrl/unica-despesa/$_despesaId?id_login=$idLogin';

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

          _selectedDate = DateTime.tryParse(data['data_vencimento'] ?? '');
          _dataVencimentoController.text =
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
          _idCategoriaSelecionada = data['id_categoria'];
        });
      } else {
        _showSnackbar('Erro ao carregar despesa');
      }
    } catch (e) {
      _showSnackbar('Erro ao carregar: $e');
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

  Future<void> atualizarDespesa() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Preencha todos os campos corretamente.");
      return;
    }

    try {
      _selectedDate = _parseDate(_dataVencimentoController.text);
      if (_recorrente) {
        if (_fimRecorrenciaController.text.trim().isEmpty) {
          _fimRecorrencia = null;
        } else {
          _fimRecorrencia = _parseDate(_fimRecorrenciaController.text);

          if (_fimRecorrencia!.isBefore(_selectedDate!) ||
              _fimRecorrencia!.isAtSameMomentAs(_selectedDate!)) {
            _showSnackbar(
                "A data de fim da recorrência deve ser posterior à data de vencimento.");
            return;
          }
        }
      }
    } catch (_) {
      _showSnackbar("Datas inválidas.");
      return;
    }

    if (_despesaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID da despesa não está definido')),
      );
      return;
    }

    final despesa = await _obterDetalhesDespesa(_despesaId!);

    if (despesa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar detalhes da despesa')),
      );
      return;
    }

    final bool recorrente = despesa['recorrencia'] ?? false;

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
      await _encerrarRecorrencia(_despesaId!);
    }
  }

  Future<void> _confirmarEEditar() async {
    final url = '$_despesasUrl/$_despesaId';

    final requestBody = {
      'descricao': _descricaoController.text,
      'valor': double.tryParse(
            _valorController.text
                .replaceAll(RegExp(r'[^\d,]'), '')
                .replaceAll(',', '.'),
          ) ??
          0.0,
      'data_vencimento': _selectedDate!.toIso8601String().split('T')[0],
      'recorrencia': _recorrente,
      'id_categoria': _idCategoriaSelecionada,
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

      int anoFim = _selectedMes! == 1 ? _selectedAno! - 1 : _selectedAno!;
      int mesFim = _selectedMes! == 1 ? 12 : _selectedMes! - 1;

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
        final insertUrl = '$baseUrl/inserir-despesa';

        _selectedDate = _parseDate(_dataVencimentoController.text);

        final novoBody = {
          "id_login": idLogin,
          "descricao": _descricaoController.text,
          "valor": double.tryParse(
                _valorController.text
                    .replaceAll(RegExp(r'[^\d,]'), '')
                    .replaceAll(',', '.'),
              ) ??
              0.0,
          "data_vencimento": _selectedDate!.toIso8601String().split('T')[0],
          "recorrencia": _recorrente,
          "id_categoria": _idCategoriaSelecionada,
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
                    'Erro ao inserir nova despesa: ${insertResponse.body}')),
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
          SwitchListTile(
            title: Row(
              children: const [
                Icon(Icons.repeat, color: Colors.blue),
                SizedBox(width: 8),
                Text('Despesa Recorrente'),
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
          if (_recorrente)
            _buildDateField(
                'Fim da Recorrência (opcional)', _fimRecorrenciaController,
                obrigatorio: false),
        ],
      ),
    );
  }

  Widget _buildCategoriaDropdown() {
    return DropdownButtonFormField<int>(
      value: _idCategoriaSelecionada,
      items: _categorias
          .map((cat) => DropdownMenuItem<int>(
                value: cat['id'],
                child: Text(cat['nome']),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _idCategoriaSelecionada = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Categoria *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) => value == null ? 'Selecione uma categoria' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inserir Despesa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Descrição *', _descricaoController),
              const SizedBox(height: 12),
              _buildDateField(
                  'Data de Vencimento *', _dataVencimentoController),
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
              _buildCategoriaDropdown(),
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
                    onPressed: atualizarDespesa,
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

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
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
          Text('Despesa recorrente'),
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
                  backgroundColor: Colors.blue, // fundtotalo azul
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
