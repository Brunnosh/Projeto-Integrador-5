import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _despesasUrl = '';
String _categoriasUrl = '';

class EditDespesaPage extends StatefulWidget {
  const EditDespesaPage({super.key});

  @override
  State<EditDespesaPage> createState() => _EditDespesaPageState();
}

class _EditDespesaPageState extends State<EditDespesaPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _fimRecorrencia;
  bool _recorrente = false;

  List<Map<String, dynamic>> _categorias = [];
  int? _idCategoriaSelecionada;
  int? _despesaId;

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

          _recorrente = data['recorrencia'] ?? false;
          if (data['fim_recorrencia'] != null) {
            _fimRecorrencia = DateTime.tryParse(data['fim_recorrencia']);
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
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _idCategoriaSelecionada == null ||
        _despesaId == null) {
      _showSnackbar("Preencha todos os campos corretamente.");
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
      'valor': double.tryParse(_valorController.text) ?? 0.0,
      'data_vencimento': _selectedDate!.toIso8601String().split('T')[0],
      'recorrencia': _recorrente,
      'fim_recorrencia': _fimRecorrencia?.toIso8601String().split('T')[0],
      'id_categoria': _idCategoriaSelecionada,
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Despesa atualizada com sucesso.');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        _showSnackbar('Erro ao atualizar: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Erro ao atualizar: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onStepContinue() {
    atualizarDespesa();
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Despesa')),
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
                  if (_recorrente)
                    _buildFimRecorrenciaPicker('Fim da Recorrência'),
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

  Widget _buildFimRecorrenciaPicker(String label) {
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
              setState(() => _fimRecorrencia = pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_fimRecorrencia == null
                ? 'Selecione a data (opcional)'
                : _fimRecorrencia!.toIso8601String().split('T')[0]),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCategoria() {
    return DropdownButtonFormField<int>(
      value: _idCategoriaSelecionada,
      onChanged: (id) => setState(() => _idCategoriaSelecionada = id),
      items: _categorias
          .map((cat) => DropdownMenuItem<int>(
                value: cat['id'],
                child: Text(utf8.decode(utf8.encode(cat['nome']))),
              ))
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
