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
  final _formKey = GlobalKey<FormState>();

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário cadastrado com sucesso!'),
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showSnackbar('Falha ao cadastrar usuário: ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Erro ao cadastrar usuário: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white, // Deixa o título e ícone brancos
          iconTheme: const IconThemeData(
              color: Colors.white), // Garante que o ícone "voltar" fique branco
          title: const Text('Criar Conta'),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Stepper(
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
                    _buildTextField('E-mail', _emailController,
                        validator: _validateEmail),
                    _buildTextField('Senha', _passwordController,
                        obscureText: true, validator: _validatePassword),
                    _buildTextField(
                        'Confirmar Senha', _confirmPasswordController,
                        obscureText: true, validator: _validateConfirmPassword),
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
        ));
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
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

  // Validações simples para os campos
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mail é obrigatório';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmar senha é obrigatório';
    }
    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }
}
