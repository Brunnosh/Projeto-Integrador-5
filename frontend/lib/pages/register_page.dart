import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/environment.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _cadastroUrl = '';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _dateController = TextEditingController();

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
      'data_nascimento': _selectedDate?.toIso8601String().split('T')[0],
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
        final responseData = json.decode(response.body);
        final token = responseData['access_token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);

          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _showSnackbar('Token não encontrado na resposta.');
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
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Criar Conta'),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, ControlsDetails details) {
              final isLastStep = _currentStep == 1;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(isLastStep ? 'Salvar' : 'Continuar'),
                    ),
                    const SizedBox(width: 16),
                    if (_currentStep > 0)
                      OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Voltar'),
                      ),
                  ],
                ),
              );
            },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: (newValue) => setState(() => _selectedState = newValue!),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label) {
    return TextFormField(
      controller: _dateController,
      keyboardType: TextInputType.number,
      inputFormatters: [DateInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
                _dateController.text =
                    DateFormat('dd/MM/yyyy').format(pickedDate);
              });
            }
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Data de nascimento é obrigatória';
        }
        try {
          final parts = value.split('/');
          if (parts.length != 3) throw Exception();
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          _selectedDate =
              DateTime(year, month, day); // define a data para envio
        } catch (_) {
          return 'Data inválida';
        }
        return null;
      },
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

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
