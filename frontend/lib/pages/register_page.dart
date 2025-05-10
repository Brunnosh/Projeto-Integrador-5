import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/environment.dart';

String _cadastroUrl = '';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  void initState() {
    super.initState();
    _setupApiUrl();
  }

  Future<void> _setupApiUrl() async {
    final isEmulator = await isRunningOnEmulator();
    setState(() {
      _cadastroUrl = isEmulator
          ? 'http://10.0.2.2:8000/cadastro' // URL para emulador Android
          : 'http://localhost:8000/cadastro'; // URL para dispositivo físico ou em desktop
    });
  }

  int _currentStep = 0;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cepController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  String _selectedState = 'AC';
  DateTime? _selectedDate;

  final Map<String, int> _stateMap = {
    'AC': 1,
    'AL': 2,
    'AP': 3,
    'AM': 4,
    'BA': 5,
    'CE': 6,
    'DF': 7,
    'ES': 8,
    'GO': 9,
    'MA': 10,
    'MT': 11,
    'MS': 12,
    'MG': 13,
    'PA': 14,
    'PB': 15,
    'PR': 16,
    'PE': 17,
    'PI': 18,
    'RJ': 19,
    'RN': 20,
    'RS': 21,
    'RO': 22,
    'RR': 23,
    'SC': 24,
    'SP': 25,
    'SE': 26,
    'TO': 27
  };

  Future<void> registerUser() async {
    // final apiUrl = 'http://localhost:8000/cadastro';
    // const apiUrl = 'http://10.0.2.2:8000/cadastro';
    final requestBody = {
      'nome': _firstNameController.text,
      'sobrenome': _lastNameController.text,
      'data_nascimento': _selectedDate?.toIso8601String(),
      'email': _emailController.text,
      'senha': _passwordController.text,
      'confirmar_senha': _confirmPasswordController.text,
      'endereco': {
        'cep': _cepController.text,
        'id_estado': _stateMap[_selectedState],
        'bairro': _neighborhoodController.text,
        'rua': _streetController.text,
        'numero': _numberController.text,
        'complemento': _complementController.text
      }
    };

    try {
      final response = await http.post(
        Uri.parse(_cadastroUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Usuário cadastrado com sucesso');
      } else {
        print('Falha ao cadastrar usuário: ${response.body}');
      }
    } catch (e) {
      print('Erro ao cadastrar usuário: $e');
    }
  }

  void _onStepContinue() {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      registerUser();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.blue,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        steps: [
          Step(
            title: const Text('Dados Pessoais'),
            content: Column(
              children: [
                _buildTextField('Nome', _firstNameController),
                _buildTextField('Sobrenome', _lastNameController),
                _buildDatePicker('Data de Nascimento'),
                _buildTextField('E-mail', _emailController),
                _buildTextField('Senha', _passwordController,
                    obscureText: true),
                _buildTextField('Confirmar Senha', _confirmPasswordController,
                    obscureText: true),
              ],
            ),
          ),
          Step(
            title: const Text('Endereço'),
            content: Column(
              children: [
                _buildDropdown(
                    'Estado', _stateMap.keys.toList(), _selectedState),
                _buildTextField('CEP', _cepController),
                _buildTextField('Bairro', _neighborhoodController),
                _buildTextField('Rua', _streetController),
                _buildTextField('Numero', _numberController),
                _buildTextField('Complemento', _complementController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: (newValue) => setState(() => _selectedState = newValue!),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      decoration: InputDecoration(labelText: label),
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
              lastDate: DateTime.now(),
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
                : _selectedDate.toString().split(' ')[0]),
          ),
        ),
      ],
    );
  }
}
