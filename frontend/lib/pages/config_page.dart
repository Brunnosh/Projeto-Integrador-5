import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ConfiguracoesPage extends StatefulWidget {
  final Map<String, dynamic> dadosUsuario;

  const ConfiguracoesPage({super.key, required this.dadosUsuario});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  String _estadosUrl = '';
  Map<int, String> estadosMap = {};

  bool _editandoNome = false;
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();

  bool _editandoEmail = false;
  final _emailController = TextEditingController();

  bool _editandoNascimento = false;
  final _nascimentoController = TextEditingController();

  bool _editandoEndereco = false;
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _complementoController = TextEditingController();
  int? _idEstadoSelecionado;

  @override
  void initState() {
    super.initState();
    _setupApiUrl();
    _inicializarControllers();
  }

  void _inicializarControllers() {
    final endereco = widget.dadosUsuario['endereco'] ?? {};
    _cepController.text = endereco['cep'] ?? '';
    _ruaController.text = endereco['rua'] ?? '';
    _numeroController.text = endereco['numero'] ?? '';
    _bairroController.text = endereco['bairro'] ?? '';
    _complementoController.text = endereco['complemento'] ?? '';
    _idEstadoSelecionado = endereco['id_estado'];
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

  String formatarData(String? data) {
    if (data == null) return 'Não informado';
    try {
      final dataParse = DateTime.parse(data);
      return DateFormat('dd/MM/yyyy').format(dataParse);
    } catch (e) {
      return 'Formato inválido';
    }
  }

  Future<void> _salvarEndereco() async {
    final idEndereco = widget.dadosUsuario['endereco']['id'];
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = Uri.parse('$baseUrl/atualizar-endereco/$idEndereco');

    final body = jsonEncode({
      "cep": _cepController.text,
      "rua": _ruaController.text,
      "numero": _numeroController.text,
      "bairro": _bairroController.text,
      "complemento": _complementoController.text,
      "id_estado": _idEstadoSelecionado,
    });

    try {
      final response = await http.put(url,
          headers: {"Content-Type": "application/json"}, body: body);

      if (response.statusCode == 200) {
        setState(() {
          _editandoEndereco = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Endereço atualizado com sucesso")),
        );
      } else {
        print('Erro: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao atualizar endereço")),
        );
      }
    } catch (e) {
      print('Erro ao enviar atualização: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final endereco = widget.dadosUsuario['endereco'] ?? {};
    final idEstado = endereco['id_estado'];
    final nomeEstado = estadosMap[idEstado] ?? 'Carregando...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Dados Pessoais'),
          // Nome
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _editandoNome
                  ? Column(
                      children: [
                        _buildEditableField('Nome', _nomeController),
                        _buildEditableField('Sobrenome', _sobrenomeController),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Salvar"),
                          onPressed: _salvarNome,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.dadosUsuario['nome']} ${widget.dadosUsuario['sobrenome']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _editandoNome = true;
                              _nomeController.text =
                                  widget.dadosUsuario['nome'] ?? '';
                              _sobrenomeController.text =
                                  widget.dadosUsuario['sobrenome'] ?? '';
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ),
          // E-mail
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _editandoEmail
                  ? Column(
                      children: [
                        _buildEditableField('E-mail', _emailController),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Salvar"),
                          onPressed: _salvarEmail,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.email, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              widget.dadosUsuario['email'] ?? 'Não informado',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _editandoEmail = true;
                              _emailController.text =
                                  widget.dadosUsuario['email'] ?? '';
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ),
          // Data de Nascimento
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _editandoNascimento
                  ? Column(
                      children: [
                        _buildEditableField(
                            'Data de Nascimento:', _nascimentoController),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Salvar"),
                          onPressed: _salvarNascimento,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cake, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              formatarData(
                                  widget.dadosUsuario['data_nascimento']),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _editandoNascimento = true;
                              _nascimentoController.text = formatarData(
                                  widget.dadosUsuario['data_nascimento']);
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Endereço'),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _editandoEndereco
                    ? [
                        _buildEditableField('CEP', _cepController),
                        _buildEstadoDropdown(),
                        _buildEditableField('Rua', _ruaController),
                        _buildEditableField('Número', _numeroController),
                        _buildEditableField('Bairro', _bairroController),
                        _buildEditableField(
                            'Complemento', _complementoController),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Salvar"),
                          onPressed: _salvarEndereco,
                        ),
                      ]
                    : [
                        _buildEnderecoRow(
                            Icons.map, 'CEP', _cepController.text),
                        _buildEnderecoRow(
                            Icons.flag,
                            'Estado',
                            estadosMap[_idEstadoSelecionado] ??
                                'Carregando...'),
                        _buildEnderecoRow(
                            Icons.home, 'Rua', _ruaController.text),
                        _buildEnderecoRow(
                            Icons.numbers, 'Número', _numeroController.text),
                        _buildEnderecoRow(Icons.location_city, 'Bairro',
                            _bairroController.text),
                        _buildEnderecoRow(Icons.place, 'Complemento',
                            _complementoController.text),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                _editandoEndereco = true;
                              });
                            },
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Future<void> _salvarNome() async {
    final idLogin = widget.dadosUsuario['id_login'];
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = Uri.parse('$baseUrl/atualizar-nome/$idLogin');

    final body = jsonEncode({
      "nome": _nomeController.text.trim(),
      "sobrenome": _sobrenomeController.text.trim(),
    });

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          widget.dadosUsuario['nome'] = _nomeController.text;
          widget.dadosUsuario['sobrenome'] = _sobrenomeController.text;
          _editandoNome = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nome atualizado com sucesso")),
        );
      } else {
        print('Erro: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao atualizar nome")),
        );
      }
    } catch (e) {
      print('Erro ao enviar atualização: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro na comunicação com o servidor")),
      );
    }
  }

  Future<void> _salvarEmail() async {
    final idLogin = widget.dadosUsuario['id_login'];
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = Uri.parse('$baseUrl/atualizar-email/$idLogin');

    final body = jsonEncode({
      "email": _emailController.text.trim(),
    });

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          widget.dadosUsuario['email'] = _emailController.text.trim();
          _editandoEmail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-mail atualizado com sucesso")),
        );
      } else {
        print('Erro: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao atualizar e-mail")),
        );
      }
    } catch (e) {
      print('Erro ao enviar atualização: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro na comunicação com o servidor")),
      );
    }
  }

  Future<void> _salvarNascimento() async {
    final idLogin = widget.dadosUsuario['id_login'];
    final isEmulator = await isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
    final url = Uri.parse('$baseUrl/atualizar-nascimento/$idLogin');

    final body = jsonEncode({
      "data_nascimento": _nascimentoController.text.trim(),
    });

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          widget.dadosUsuario['data_nascimento'] =
              _nascimentoController.text.trim();
          _editandoNascimento = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Data de nascimento atualizado com sucesso")),
        );
      } else {
        print('Erro: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao atualizar data de nascimento")),
        );
      }
    } catch (e) {
      print('Erro ao enviar atualização: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro na comunicação com o servidor")),
      );
    }
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<int>(
        value: _idEstadoSelecionado,
        items: estadosMap.entries
            .map((entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)))
            .toList(),
        onChanged: (value) {
          setState(() {
            _idEstadoSelecionado = value;
          });
        },
        decoration: const InputDecoration(
          labelText: 'Estado',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildEnderecoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${value ?? 'Não informado'}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
