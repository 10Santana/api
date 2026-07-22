import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFBC02D)),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}

// ================= TELA DE LOGIN =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  void _entrar() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao entrar: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month, size: 60, color: Color(0xFFFBC02D)),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController, 
                style: const TextStyle(color: Colors.white), 
                decoration: const InputDecoration(labelText: 'E-mail', labelStyle: TextStyle(color: Colors.grey))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _senhaController, 
                obscureText: true, 
                style: const TextStyle(color: Colors.white), 
                decoration: const InputDecoration(labelText: 'Senha', labelStyle: TextStyle(color: Colors.grey))
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, 
                height: 48, 
                child: ElevatedButton(
                  onPressed: _entrar, 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D)), 
                  child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold))
                )
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const RegisterScreen())
                  );
                }, 
                child: const Text('Criar conta pela primeira vez', style: TextStyle(color: Color(0xFFFBC02D)))
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= TELA DE CADASTRO DETALHADA =================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeCompletoController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  Future<void> _escolherDataNascimento(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFFBC02D))),
        child: child!,
      ),
    );
    if (dataEscolhida != null) {
      setState(() {
        _dataNascimentoController.text = "${dataEscolhida.day}/${dataEscolhida.month}/${dataEscolhida.year}";
      });
    }
  }

  void _cadastrarUsuario() async {
    if (_nomeCompletoController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _senhaController.text.isEmpty ||
        _dataNascimentoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha todos os campos!")),
      );
      return;
    }

    try {
      // 1. Cria o usuário no Firebase Auth
      UserCredential credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      // 2. Salva nome completo e data de nascimento no Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(credencial.user!.uid).set({
        'nomeCompleto': _nomeCompletoController.text.trim(),
        'email': _emailController.text.trim(),
        'dataNascimento': _dataNascimentoController.text.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Retorna para a tela de login/home autenticada
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao cadastrar: ${e.toString()}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        title: const Text('Criar Nova Conta', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add, size: 50, color: Color(0xFFFBC02D)),
                const SizedBox(height: 20),
                TextField(
                  controller: _nomeCompletoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nome Completo', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'E-mail', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Senha (mínimo 6 caracteres)', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _escolherDataNascimento(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dataNascimentoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Data de Nascimento',
                        labelStyle: TextStyle(color: Colors.grey),
                        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFFFBC02D)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cadastrarUsuario,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D)),
                    child: const Text('CADASTRAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= TELA PRINCIPAL =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _abaAtual = 'AG FIGHT';
  final _nomePessoaController = TextEditingController();
  final _dataController = TextEditingController();

  Future<void> _escolherData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFFBC02D))),
        child: child!,
      ),
    );
    if (dataEscolhida != null) {
      setState(() {
        _dataController.text = "${dataEscolhida.day}/${dataEscolhida.month}/${dataEscolhida.year}";
      });
    }
  }

  void _abrirCadastroPresenca(BuildContext context) {
    _nomePessoaController.clear();
    _dataController.text = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 25, right: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Adicionar Presença em: $_abaAtual', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _campoTexto(_nomePessoaController, 'Nome da Pessoa', Icons.person),
            const SizedBox(height: 15),
            GestureDetector(onTap: () => _escolherData(context), child: AbsorbPointer(child: _campoTexto(_dataController, 'Data do Culto / Evento', Icons.calendar_month))),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: () async {
                if (_nomePessoaController.text.isNotEmpty && _dataController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection('cultos').add({
                      'categoria': _abaAtual,
                      'nomePessoa': _nomePessoaController.text.trim(),
                      'data': _dataController.text.trim(),
                      'criadoEm': FieldValue.serverTimestamp(),
                    });
                    _nomePessoaController.clear();
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('SALVAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto(TextEditingController controller, String label, IconData icone) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), prefixIcon: Icon(icone, color: const Color(0xFFFBC02D)), filled: true, fillColor: const Color(0xFF2D2D2D), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(backgroundColor: const Color(0xFFFBC02D), title: Text(_abaAtual, style: const TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: _abaAtual == 'AG FIGHT' 
          ? null 
          : FloatingActionButton(backgroundColor: const Color(0xFFFBC02D), onPressed: () => _abrirCadastroPresenca(context), child: const Icon(Icons.add, color: Colors.black)),
      drawer: Drawer(
        backgroundColor: const Color(0xFF2D2D2D),
        child: ListView(
          children: [
            const DrawerHeader(child: Center(child: Text('APP FIGHT', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))),
            _buildDrawerItem('AG FIGHT'),
            _buildDrawerItem('Arena'),
            _buildDrawerItem('Culto Da Familia'),
            _buildDrawerItem('Culto De Terca'),
            const Divider(color: Colors.grey),
            ListTile(title: const Text('Log Out', style: TextStyle(color: Colors.red)), onTap: () => FirebaseAuth.instance.signOut()),
          ],
        ),
      ),
      body: _abaAtual == 'AG FIGHT' ? _buildTelaAvisos() : _buildTelaRelatorioAgrupado(),
    );
  }

  Widget _buildTelaAvisos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Atividades desta semana', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Participe, convide e viva o que Deus tem para nós!', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _cardAviso(titulo: 'Sara Conference SP', data: '23/07/2026', categoria: 'Regional', corTag: Colors.blue),
              _cardAviso(titulo: 'Arena Esquenta', data: '01/08/2026', categoria: 'Arena', corTag: Colors.green),
              _cardAviso(titulo: 'Churrasco Homens Santa Brasa', data: '07/08/2026', categoria: 'Eventos especiais', corTag: Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardAviso({required String titulo, required String data, required String categoria, required Color corTag}) {
    return Container(
      width: 280,
      height: 340,
      decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Center(child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: corTag, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(categoria, style: TextStyle(color: corTag, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelaRelatorioAgrupado() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cultos').where('categoria', isEqualTo: _abaAtual).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFBC02D)));
        
        var docs = snapshot.data!.docs;
        Map<String, Map<String, dynamic>> eventosAgrupados = {};

        for (var doc in docs) {
          var dataMap = doc.data() as Map<String, dynamic>? ?? {};
          String data = dataMap['data'] ?? 'Sem data';
          String nomePessoa = dataMap['nomePessoa'] ?? dataMap['nomeEvento'] ?? dataMap['nome'] ?? 'Participante';

          if (!eventosAgrupados.containsKey(data)) {
            eventosAgrupados[data] = {
              'data': data,
              'participantes': <Map<String, String>>[]
            };
          }
          
          (eventosAgrupados[data]!['participantes'] as List).add({
            'id': doc.id,
            'nome': nomePessoa,
          });
        }

        var listaDatas = eventosAgrupados.values.toList();

        if (listaDatas.isEmpty) {
          return Center(
            child: Text('Nenhum registro em $_abaAtual.', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total de Dias Registrados: ${listaDatas.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 5),
                itemCount: listaDatas.length,
                itemBuilder: (context, index) {
                  final itemData = listaDatas[index];
                  final data = itemData['data'];
                  final List participantes = itemData['participantes'];
                  final int quantidade = participantes.length;

                  return Card(
                    color: const Color(0xFF2D2D2D),
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const Icon(Icons.calendar_today, color: Color(0xFFFBC02D)),
                      title: Text('$_abaAtual - $data', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text('Toque para ver a lista de presença', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      onTap: () => _mostrarDetalhesParticipantes(context, data, participantes),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(8)),
                            child: Text('$quantidade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              for (var p in participantes) {
                                await FirebaseFirestore.instance.collection('cultos').doc(p['id']).delete();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDetalhesParticipantes(BuildContext context, String data, List participantes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 15),
            const Text('Lista de Presença', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Data: $data — Total: ${participantes.length} pessoa(s)', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const Divider(color: Colors.grey, height: 25),
            Expanded(
              child: ListView.builder(
                itemCount: participantes.length,
                itemBuilder: (context, index) {
                  final p = participantes[index];
                  return ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFFFBC02D)),
                    title: Text(p['nome'], style: const TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('cultos').doc(p['id']).delete();
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title) {
    return ListTile(
      title: Text(title, style: TextStyle(color: _abaAtual == title ? const Color(0xFFFBC02D) : Colors.white)),
      onTap: () {
        setState(() => _abaAtual = title);
        Navigator.pop(context);
      },
    );
  }
}