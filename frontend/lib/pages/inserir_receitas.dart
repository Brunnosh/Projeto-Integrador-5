import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/environment.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

String _receitasUrl = '';

class InserirReceitaPage extends StatefulWidget {
  const InserirReceitaPage({super.key});

  @override
  State<InserirReceitaPage> createState() => _InserirReceitaPageState();
}

class _InserirReceitaPageState extends State<InserirReceitaPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataRecebimentoController = TextEditingController();
  final _fimRecorrenciaController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _fimRecorrencia;
  bool _recorrente = false;

  DateTime _parseDate(String input) {
    return DateFormat('dd/MM/yyyy').parseStrict(input);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _setupApiUrl();
  }

  Future<void> _setupApiUrl() async {
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    setState(() {
      _receitasUrl = '$baseUrl/inserir-receita';
    });
  }

  Future<void> inserirReceita() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Preencha todos os campos corretamente.");
      return;
    }

    try {
      _selectedDate = _parseDate(_dataRecebimentoController.text);
      if (_recorrente && _fimRecorrenciaController.text.isNotEmpty) {
        _fimRecorrencia = _parseDate(_fimRecorrenciaController.text);

        if (_fimRecorrencia!.isBefore(_selectedDate!) ||
            _fimRecorrencia!.isAtSameMomentAs(_selectedDate!)) {
          _showSnackbar(
              "A data de fim da recorrência deve ser posterior à data de vencimento.");
          return;
        }
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

    final requestBody = {
      'id_login': idLogin,
      'descricao': _descricaoController.text,
      'valor': double.tryParse(
            _valorController.text
                .replaceAll(RegExp(r'[^\d,]'), '')
                .replaceAll(',', '.'),
          ) ??
          0.0,
      'data_recebimento': _selectedDate!.toIso8601String().split('T')[0],
      'recorrencia': _recorrente,
    };

    if (_fimRecorrencia != null) {
      requestBody['fim_recorrencia'] =
          _fimRecorrencia!.toIso8601String().split('T')[0];
    }

    try {
      final response = await http.post(
        Uri.parse(_receitasUrl),
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
        _showSnackbar('Erro ao inserir: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Erro ao inserir: $e');
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
      appBar: AppBar(title: const Text('Inserir Receita')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Descrição *', _descricaoController),
              const SizedBox(height: 12),
              _buildDateField(
                  'Data de Recebimento *', _dataRecebimentoController),
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
                    onPressed: inserirReceita,
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
