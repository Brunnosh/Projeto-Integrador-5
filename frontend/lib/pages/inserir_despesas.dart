import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _despesasUrl = '';
String _categoriasUrl = '';

class InserirDespesaPage extends StatefulWidget {
  const InserirDespesaPage({super.key});

  @override
  State<InserirDespesaPage> createState() => _InserirDespesaPageState();
}

class _InserirDespesaPageState extends State<InserirDespesaPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  DateTime? _selectedDate;
  bool _recorrente = false;

  List<Map<String, dynamic>> _categorias = [];
  int? _idCategoriaSelecionada;

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
      _despesasUrl = '$baseUrl/inserir-despesa';
      _categoriasUrl = '$baseUrl/categoria';
    });
    _carregarCategorias();
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

  Future<void> inserirDespesa() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _idCategoriaSelecionada == null) {
      _showSnackbar("Preencha todos os campos corretamente.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _showSnackbar('Usuário não autenticado.');
      return;
    }

    final idLogin = prefs.getString('userId');

    if (idLogin == null) {
      _showSnackbar('ID do usuário não encontrado.');
      return;
    }

    final requestBody = {
      'id_login': idLogin,
      'descricao': _descricaoController.text,
      'valor': double.tryParse(_valorController.text) ?? 0.0,
      'data_vencimento': _selectedDate!.toIso8601String().split('T')[0],
      'recorrencia': _recorrente,
      'id_categoria': _idCategoriaSelecionada,
    };

    try {
      final response = await http.post(
        Uri.parse(_despesasUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8'
        }, // Garantir UTF-8
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _showSnackbar(responseData['mensagem']);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showSnackbar('Erro ao inserir: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Erro ao inserir: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onStepContinue() {
    inserirDespesa();
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inserir Despesa')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          steps: [
            Step(
              title: const Text('Detalhes da Despesa'),
              content: Column(
                children: [
                  _buildTextField('Descrição', _descricaoController),
                  _buildTextField('Valor', _valorController,
                      keyboardType: TextInputType.number),
                  _buildDatePicker('Data de Vencimento'),
                  _buildCheckbox('Recorrente', _recorrente),
                  _buildDropdownCategoria(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.isEmpty ? 'Campo obrigatório' : null,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildCheckbox(String label, bool value) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (newValue) => setState(() => _recorrente = newValue ?? false),
    );
  }

  Widget _buildDropdownCategoria() {
    return DropdownButtonFormField<int>(
      value: _idCategoriaSelecionada,
      onChanged: (id) => setState(() => _idCategoriaSelecionada = id),
      items: _categorias
          .map((cat) => DropdownMenuItem<int>(
              value: cat['id'],
              child: Text(
                utf8.decode(utf8.encode(cat['nome'])), // Força a decodificação
              )))
          .toList(),
      decoration: const InputDecoration(labelText: 'Categoria'),
    );
  }

  Widget _buildDatePicker(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() => _selectedDate = pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_selectedDate == null
                ? 'Selecione a data'
                : _selectedDate!.toIso8601String().split('T')[0]),
          ),
        ),
      ],
    );
  }
}
