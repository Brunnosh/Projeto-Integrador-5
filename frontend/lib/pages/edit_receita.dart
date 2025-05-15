import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _receitasUrl = '';

class EditReceitaPage extends StatefulWidget {
  const EditReceitaPage({super.key});

  @override
  State<EditReceitaPage> createState() => _EditReceitaPageState();
}

class _EditReceitaPageState extends State<EditReceitaPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _fimRecorrencia;
  bool _recorrente = false;

  int? _receitaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _receitaId = args['id'];
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
          _valorController.text = data['valor']?.toString() ?? '';
          _selectedDate = DateTime.parse(data['data_recebimento']);
          _recorrente = data['recorrencia'] ?? false;
          if (data['fim_recorrencia'] != null) {
            _fimRecorrencia = DateTime.tryParse(data['fim_recorrencia']);
          }
        });
      } else {
        _showSnackbar('Erro ao carregar receita');
      }
    } catch (e) {
      _showSnackbar('Erro ao carregar: $e');
    }
  }

  Future<void> atualizarReceita() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _receitaId == null) {
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

    final url = '$_receitasUrl/$_receitaId?id_login=$idLogin';

    final requestBody = {
      'id_login': idLogin,
      'descricao': _descricaoController.text,
      'valor': double.tryParse(_valorController.text) ?? 0.0,
      'data_recebimento': _selectedDate!.toIso8601String().split('T')[0],
      'recorrencia': _recorrente,
      'fim_recorrencia': _fimRecorrencia?.toIso8601String().split('T')[0],
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Receita atualizada com sucesso.');
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
    atualizarReceita();
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Receita')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          steps: [
            Step(
              title: const Text('Detalhes da Receita'),
              content: Column(
                children: [
                  _buildTextField('Descrição', _descricaoController),
                  _buildTextField('Valor', _valorController,
                      keyboardType: TextInputType.number),
                  _buildDatePicker('Data de Recebimento'),
                  _buildCheckbox('Recorrente', _recorrente),
                  if (_recorrente)
                    _buildFimRecorrenciaPicker('Fim da Recorrência'),
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
