import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controle de etapas
  int _currentStep = 0;

  // Controle dos campos
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cepController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _streetController = TextEditingController();
  String _selectedState = 'AC';
  DateTime? _selectedDate;

  // Lista dos estados do Brasil
  final List<String> _states = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
    'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white, // Deixa o título e ícone brancos
        iconTheme: const IconThemeData(color: Colors.white), // Garante que o ícone "voltar" fique branco
        title: const Text('Criar Conta'),
        elevation: 0,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Column(
            children: [
              const SizedBox(height: 24),
              if (_currentStep == 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.blue),
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue), // Cor azul
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: const Text('Continuar'),
                ),
              const SizedBox(height: 10),
              if (_currentStep > 0)
                ElevatedButton(
                  onPressed: details.onStepCancel,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white), // Cor branca para Voltar
                    foregroundColor: MaterialStateProperty.all(Colors.blue), // Cor azul no texto
                  ),
                  child: const Text('Voltar'),
                ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Dados Pessoais'),
            content: Column(
              children: [
                _buildTextField('Nome', controller: _firstNameController),
                const SizedBox(height: 16),
                _buildTextField('Sobrenome', controller: _lastNameController),
                const SizedBox(height: 16),
                _buildDatePicker('Data de Nascimento'),
                const SizedBox(height: 16),
                _buildTextField('E-mail', controller: _emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField('Senha', controller: _passwordController, obscureText: true),
                const SizedBox(height: 16),
                _buildTextField('Confirmar Senha', controller: _confirmPasswordController, obscureText: true),
              ],
            ),
          ),
          Step(
            title: const Text('Endereço'),
            content: Column(
              children: [
                _buildDropdown('Estado', _states, _selectedState),
                const SizedBox(height: 16),
                _buildTextField('CEP', controller: _cepController, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField('Bairro', controller: _neighborhoodController),
                const SizedBox(height: 16),
                _buildTextField('Rua', controller: _streetController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para criar o campo de texto
  Widget _buildTextField(String label, {TextEditingController? controller, TextInputType? keyboardType, bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blue.shade50,
            hintText: 'Digite seu $label',
            hintStyle: const TextStyle(color: Colors.blueGrey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
      ],
    );
  }

  // Método para exibir o calendário de data
  Widget _buildDatePicker(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _selectedDate == null
                  ? 'Escolha a data'
                  : '${_selectedDate?.toLocal()}'.split(' ')[0],
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),
        ),
      ],
    );
  }

  // Função para abrir o calendário
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Método para criar o Dropdown dos estados
  Widget _buildDropdown(String label, List<String> items, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: (newValue) {
            setState(() {
              _selectedState = newValue!;
            });
          },
          items: items.map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state),
            );
          }).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // Lógica de navegação entre as etapas
  void _onStepContinue() {
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      print("Cadastro Completo");
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
}