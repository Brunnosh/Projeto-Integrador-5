import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/environment.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:flutter_multi_formatter/formatters/money_input_formatter.dart';

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
          _valorController.text = data['valor']?.toString() ?? '';

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

  Future<void> atualizarDespesa() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Preencha todos os campos corretamente.");
      return;
    }

    try {
      _selectedDate = _parseDate(_dataVencimentoController.text);
      if (_recorrente && _fimRecorrenciaController.text.isNotEmpty) {
        _fimRecorrencia = _parseDate(_fimRecorrenciaController.text);
      }
    } catch (_) {
      _showSnackbar("Datas inválidas.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final idLogin = prefs.getString('userId');

    if (token == null || idLogin == null) {
      _showSnackbar('Usuário não autenticado.');
      return;
    }

    final url = '$_despesasUrl/$_despesaId?id_login=$idLogin';

    final requestBody = {
      'id_login': idLogin,
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
                  MoneyInputFormatter(
                    thousandSeparator: ThousandSeparator.Period,
                    mantissaLength: 2,
                    trailingSymbol: '',
                    leadingSymbol: 'R\$ ',
                  )
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
