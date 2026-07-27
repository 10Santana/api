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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao entrar: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
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
                const Icon(Icons.campaign, size: 60, color: Color(0xFFFBC02D)),
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
                    child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))
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
      ),
    );
  }
}

// ================= TELA DE CADASTRO =================
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
        _dataNascimentoController.text = "${dataEscolhida.day.toString().padLeft(2, '0')}/${dataEscolhida.month.toString().padLeft(2, '0')}/${dataEscolhida.year}";
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
      UserCredential credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('usuarios').doc(credencial.user!.uid).set({
        'nomeCompleto': _nomeCompletoController.text.trim(),
        'email': _emailController.text.trim(),
        'dataNascimento': _dataNascimentoController.text.trim(),
        'tipoAdmin': 'cultos',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao cadastrar: ${e.toString()}"))
        );
      }
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

  final _tituloAvisoController = TextEditingController();
  final _dataAvisoController = TextEditingController();
  final _categoriaAvisoController = TextEditingController();
  final _imagemAvisoController = TextEditingController();
  
  String _nomeUsuario = 'Carregando...';
  String _tipoAdmin = 'nenhum';

  @override
  void initState() {
    super.initState();
    _verificarDadosUsuario();
  }

  Future<void> _verificarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          String nomeEncontrado = data['nomeCompleto'] ?? data['nome'] ?? data['displayName'] ?? '';
          if (nomeEncontrado.isEmpty && user.displayName != null) {
            nomeEncontrado = user.displayName!;
          }
          
          if (mounted) {
            setState(() {
              _nomeUsuario = nomeEncontrado.isNotEmpty ? nomeEncontrado : (user.email?.split('@')[0] ?? 'Membro');
              _tipoAdmin = data['tipoAdmin'] ?? 'nenhum';
            });
          }
          return;
        }
      } catch (e) {
        debugPrint("Erro ao buscar dados do usuário: $e");
      }
    }
    if (mounted) {
      setState(() {
        _nomeUsuario = 'Membro';
      });
    }
  }

  Future<void> _escolherData(BuildContext context, TextEditingController controller) async {
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
        controller.text = "${dataEscolhida.day.toString().padLeft(2, '0')}/${dataEscolhida.month.toString().padLeft(2, '0')}/${dataEscolhida.year}";
      });
    }
  }

  void _abrirCadastroPresenca(BuildContext context) {
    _nomePessoaController.clear();
    final now = DateTime.now();
    _dataController.text = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

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
            GestureDetector(onTap: () => _escolherData(context, _dataController), child: AbsorbPointer(child: _campoTexto(_dataController, 'Data do Culto / Evento', Icons.calendar_month))),
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

  void _abrirCadastroAviso(BuildContext context, {String? docId, Map<String, dynamic>? dados}) {
    if (_tipoAdmin != 'principal') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Apenas o Admin Principal pode gerenciar avisos.")),
      );
      return;
    }

    if (dados != null) {
      _tituloAvisoController.text = dados['titulo'] ?? '';
      _dataAvisoController.text = dados['data'] ?? '';
      _categoriaAvisoController.text = dados['categoria'] ?? '';
      _imagemAvisoController.text = dados['imagemUrl'] ?? '';
    } else {
      _tituloAvisoController.clear();
      _dataAvisoController.clear();
      _categoriaAvisoController.clear();
      _imagemAvisoController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 25, right: 25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(docId == null ? 'Adicionar Novo Aviso / Evento' : 'Editar Aviso / Evento', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _campoTexto(_tituloAvisoController, 'Título do Evento', Icons.title),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => _escolherData(context, _dataAvisoController), 
                child: AbsorbPointer(child: _campoTexto(_dataAvisoController, 'Data (ex: 23/07/2026)', Icons.calendar_month))
              ),
              const SizedBox(height: 15),
              _campoTexto(_categoriaAvisoController, 'Categoria (ex: Regional, Arena)', Icons.category),
              const SizedBox(height: 15),
              _campoTexto(_imagemAvisoController, 'URL da Imagem (Opcional)', Icons.image),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, 
                height: 50, 
                child: ElevatedButton(
                  onPressed: () async {
                    if (_tituloAvisoController.text.isNotEmpty && _dataAvisoController.text.isNotEmpty) {
                      try {
                        final dadosAviso = {
                          'titulo': _tituloAvisoController.text.trim(),
                          'data': _dataAvisoController.text.trim(),
                          'categoria': _categoriaAvisoController.text.trim().isEmpty ? 'Geral' : _categoriaAvisoController.text.trim(),
                          'imagemUrl': _imagemAvisoController.text.trim(),
                        };

                        if (docId == null) {
                          dadosAviso['criadoEm'] = FieldValue.serverTimestamp() as dynamic;
                          await FirebaseFirestore.instance.collection('avisos').add(dadosAviso);
                        } else {
                          await FirebaseFirestore.instance.collection('avisos').doc(docId).update(dadosAviso);
                        }

                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(docId == null ? "Aviso adicionado com sucesso!" : "Aviso atualizado com sucesso!")));
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar aviso: $e")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(docId == null ? 'PUBLICAR AVISO' : 'SALVAR ALTERAÇÕES', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
    bool podeVerFab = (_tipoAdmin == 'principal' && _abaAtual == 'AG FIGHT') || 
                      ((_tipoAdmin == 'principal' || _tipoAdmin == 'cultos') && _abaAtual != 'AG FIGHT');

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC02D),
        title: Text(_abaAtual, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: podeVerFab
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFBC02D),
              onPressed: () {
                if (_abaAtual == 'AG FIGHT') {
                  _abrirCadastroAviso(context);
                } else {
                  _abrirCadastroPresenca(context);
                }
              },
              icon: Icon(
                _abaAtual == 'AG FIGHT' ? Icons.campaign : Icons.add,
                color: Colors.black,
              ),
              label: Text(
                _abaAtual == 'AG FIGHT' ? 'Novo Aviso' : 'Adicionar',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      drawer: Drawer(
        backgroundColor: const Color(0xFF2D2D2D),
        child: ListView(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text('APP FIGHT', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            _buildDrawerItem('AG FIGHT'),
            _buildDrawerItem('Arena'),
            _buildDrawerItem('Culto Da Familia'),
            _buildDrawerItem('Culto De Terca'),
            const Divider(color: Colors.grey),
            ListTile(
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),
      body: _abaAtual == 'AG FIGHT' ? _buildTelaAvisosMobile() : _buildTelaRelatorioAgrupado(),
    );
  }

  Widget _buildTelaAvisosMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.waving_hand, color: Color(0xFFFBC02D), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $_nomeUsuario!',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Que bom ter você aqui. Tenha uma ótima semana!',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Atividades desta semana', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Participe, convide e viva o que Deus tem para nós!', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 14),
          SizedBox(
            height: 330,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('avisos').orderBy('criadoEm', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFBC02D)));
                }

                var docs = snapshot.data!.docs;
                
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum aviso cadastrado no momento.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var dataAviso = doc.data() as Map<String, dynamic>;
                    String docId = doc.id;
                    String titulo = dataAviso['titulo'] ?? '';
                    String dataEv = dataAviso['data'] ?? '';
                    String categoria = dataAviso['categoria'] ?? 'Geral';
                    String imagemUrl = dataAviso['imagemUrl'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _cardAviso(
                        context: context,
                        docId: docId,
                        titulo: titulo, 
                        data: dataEv, 
                        categoria: categoria, 
                        corTag: Colors.blue,
                        imagemUrl: imagemUrl,
                        dadosCompletos: dataAviso,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAviso({
    required BuildContext context,
    required String docId,
    required String titulo, 
    required String data, 
    required String categoria, 
    required Color corTag, 
    String? imagemUrl,
    required Map<String, dynamic> dadosCompletos,
  }) {
    bool podeGerenciarAvisos = (_tipoAdmin == 'principal');

    return Container(
      width: 260,
      height: 330,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900], 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: (imagemUrl != null && imagemUrl.isNotEmpty)
                  ? DecorationImage(
                      image: imagemUrl.startsWith('http') 
                          ? NetworkImage(imagemUrl) as ImageProvider
                          : AssetImage(imagemUrl), 
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (imagemUrl == null || imagemUrl.isEmpty)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        titulo, 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: corTag, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(categoria, style: TextStyle(color: corTag, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(data, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  if (podeGerenciarAvisos)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 28,
                          child: TextButton.icon(
                            onPressed: () => _abrirCadastroAviso(context, docId: docId, dados: dadosCompletos),
                            icon: const Icon(Icons.edit, color: Color(0xFFFBC02D), size: 14),
                            label: const Text('Editar', style: TextStyle(color: Color(0xFFFBC02D), fontSize: 11)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 28,
                          child: TextButton.icon(
                            onPressed: () async {
                              bool? confirmar = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF2D2D2D),
                                  title: const Text('Excluir Aviso', style: TextStyle(color: Colors.white)),
                                  content: const Text('Tem certeza que deseja excluir este aviso?', style: TextStyle(color: Colors.grey)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmar == true) {
                                await FirebaseFirestore.instance.collection('avisos').doc(docId).delete();
                              }
                            },
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 14),
                            label: const Text('Excluir', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelaRelatorioAgrupado() {
    bool podeGerenciarCultos = (_tipoAdmin == 'principal' || _tipoAdmin == 'cultos');

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
            child: Text('Nenhum registro em $_abaAtual.', style: const TextStyle(color: Colors.grey, fontSize: 15)),
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
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: const Icon(Icons.calendar_today, color: Color(0xFFFBC02D)),
                      title: Text('$_abaAtual - $data', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text('Toque para ver a lista de presença', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      onTap: () => _mostrarDetalhesParticipantes(context, data, participantes),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(8)),
                            child: Text('$quantidade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          if (podeGerenciarCultos)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 19),
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
    bool podeGerenciarCultos = (_tipoAdmin == 'principal' || _tipoAdmin == 'cultos');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 15),
            const Text('Lista de Presença', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Data: $data — Total: ${participantes.length} pessoa(s)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Divider(color: Colors.grey, height: 22),
            Expanded(
              child: ListView.builder(
                itemCount: participantes.length,
                itemBuilder: (context, index) {
                  final p = participantes[index];
                  return ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFFFBC02D)),
                    title: Text(p['nome'], style: const TextStyle(color: Colors.white)),
                    trailing: podeGerenciarCultos
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('cultos').doc(p['id']).delete();
                              if (context.mounted) Navigator.pop(context);
                            },
                          )
                        : null,
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
      onTap: () => {
        setState(() => _abaAtual = title),
        Navigator.pop(context)
      },
    );
  }
}