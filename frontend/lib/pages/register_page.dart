import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _dateController = TextEditingController();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
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
  final _formKey = GlobalKey<FormState>();
  Map<int, String> estadosMap = {};
  String _selectedState = 'Selecione';
  String _cadastroUrl = '';
  String _estadosUrl = '';
  int _currentStep = 0;
  DateTime? _selectedDate;

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
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

    if (_confirmPasswordController.value != _passwordController.value) {
      return 'As senhas não coincidem';
    }

    final isStrongPassword = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$');

    if (!isStrongPassword.hasMatch(value)) {
      return 'A senha deve ter pelo menos 8 caracteres, incluindo letra maiúscula, minúscula, número e caractere especial';
    }

    return null;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKeyStep1.currentState!.validate()) {
        setState(() => _currentStep++);
      } else {
        _showSnackbar('Preencha todos os campos obrigatórios.');
      }
    } else if (_currentStep == 1) {
      if (_formKeyStep2.currentState!.validate()) {
        registerUser();
      } else {
        _showSnackbar('Preencha todos os campos obrigatórios.');
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  void initState() {
    super.initState();
    _setupApiUrl();
  }

  Future<bool> isRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  Future<void> _setupApiUrl() async {
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    _cadastroUrl = '$baseUrl/cadastro';
    _estadosUrl = '$baseUrl/estados';
    await _carregarEstados();
  }

  Future<void> _carregarEstados() async {
    try {
      final response = await http.get(Uri.parse(_estadosUrl));
      if (response.statusCode == 200) {
        final String bodyUtf8 = utf8.decode(response.bodyBytes);
        final List<dynamic> estados = jsonDecode(bodyUtf8);
        setState(() {
          estadosMap = {
            for (var estado in estados) estado['id']: estado['nome']
          };
        });
      } else {
        print('Erro ao carregar estados: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar estados: $e');
    }
  }

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
        'id_estado': estadosMap.entries
            .firstWhere((e) => e.value == _selectedState,
                orElse: () => const MapEntry(0, ''))
            .key,
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
          errorMaxLines: 3,
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
    final dropdownItems = ['Selecione', ...items];
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
        validator: (value) {
          if (value == null || value == 'Selecione') {
            return 'Selecione um estado válido';
          }
          return null;
        },
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
                        foregroundColor: Colors.white,
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
                content: Form(
                    key: _formKeyStep1,
                    child: Column(
                      children: [
                        _buildTextField('Nome *', _firstNameController,
                            validator: _validateRequired),
                        _buildTextField('Sobrenome *', _lastNameController,
                            validator: _validateRequired),
                        _buildDatePicker('Data de Nascimento *'),
                        _buildTextField('E-mail *', _emailController,
                            validator: _validateEmail),
                        _buildTextField('Senha *', _passwordController,
                            obscureText: true, validator: _validatePassword),
                        _buildTextField(
                            'Confirmar Senha *', _confirmPasswordController,
                            obscureText: true, validator: _validatePassword),
                      ],
                    )),
              ),
              Step(
                title: const Text('Endereço'),
                content: Form(
                    key: _formKeyStep2,
                    child: Column(
                      children: [
                        _buildDropdown('Estado *', estadosMap.values.toList(),
                            _selectedState),
                        _buildTextField('CEP *', _cepController,
                            validator: _validateRequired),
                        _buildTextField('Bairro *', _neighborhoodController,
                            validator: _validateRequired),
                        _buildTextField('Rua *', _streetController,
                            validator: _validateRequired),
                        _buildTextField('Numero *', _numberController,
                            validator: _validateRequired),
                        _buildTextField('Complemento', _complementController),
                      ],
                    )),
              ),
            ],
          ),
        ));
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
