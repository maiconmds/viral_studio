import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viral Studio',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viral Studio — Fase 1')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bem-vindo! Nesta fase você pode configurar suas credenciais e testar a narração (TTS) com pré‑escuta de vozes.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
              icon: const Icon(Icons.settings),
              label: const Text('Configurações / Credenciais'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TtsPreviewPage()),
              ),
              icon: const Icon(Icons.record_voice_over),
              label: const Text('Narração — Pré‑escuta de vozes'),
            ),
            const Spacer(),
            const Text('Próximas fases: Gemini/Imagen, FFmpeg (zoom-in) e Upload YouTube.'),
          ],
        ),
      ),
    );
  }
}

// ===== Settings (credenciais) =====
final secure = FlutterSecureStorage();
final studioBaseUrlProvider = StateProvider<String?>((_) => null);
final studioApiKeyProvider = StateProvider<String?>((_) => null);
final coquiUrlProvider = StateProvider<String?>((_) => null);

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _form = GlobalKey<FormState>();
  final _baseCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _coquiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final base = await secure.read(key: 'STUDIO_BASE_URL');
    final key = await secure.read(key: 'STUDIO_API_KEY');
    final coqui = await secure.read(key: 'COQUI_API_URL');
    setState(() {
      _baseCtrl.text = base ?? '';
      _keyCtrl.text = key ?? '';
      _coquiCtrl.text = coqui ?? '';
    });
    ref.read(studioBaseUrlProvider.notifier).state = base;
    ref.read(studioApiKeyProvider.notifier).state = key;
    ref.read(coquiUrlProvider.notifier).state = coqui;
  }

  Future<void> _save() async {
    await secure.write(key: 'STUDIO_BASE_URL', value: _baseCtrl.text.trim());
    await secure.write(key: 'STUDIO_API_KEY', value: _keyCtrl.text.trim());
    await secure.write(key: 'COQUI_API_URL', value: _coquiCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciais salvas com segurança.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações / Credenciais')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Google AI Studio (Gemini/Imagen)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _baseCtrl,
              decoration: const InputDecoration(
                labelText: 'STUDIO_BASE_URL',
                hintText: 'Ex.: https://generativelanguage.googleapis.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                labelText: 'STUDIO_API_KEY',
                hintText: 'Cole sua API key do AI Studio aqui',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const Text('Coqui TTS (opcional — se tiver um endpoint próprio)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _coquiCtrl,
              decoration: const InputDecoration(
                labelText: 'COQUI_API_URL',
                hintText: 'Ex.: https://minha-coqui/tts',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== TTS Preview =====
class TtsPreviewPage extends StatefulWidget {
  const TtsPreviewPage({super.key});
  @override
  State<TtsPreviewPage> createState() => _TtsPreviewPageState();
}

class _TtsPreviewPageState extends State<TtsPreviewPage> {
  final FlutterTts tts = FlutterTts();
  List<dynamic> voices = [];
  String? selectedName;
  final sampleCtrl = TextEditingController(
    text: 'Esta é uma prévia de voz. Como deseja que eu narre o seu vídeo?',
  );

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final v = await tts.getVoices;
      setState(() => voices = v ?? []);
    } catch (_) {}
  }

  Future<void> _play() async {
    if (selectedName != null && selectedName!.isNotEmpty) {
      await tts.setVoice({'name': selectedName!});
    }
    await tts.setSpeechRate(0.9);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.speak(sampleCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Narração — Pré‑escuta de vozes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: sampleCtrl,
              decoration: const InputDecoration(
                labelText: 'Texto de amostra',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Escolha a voz',
                border: OutlineInputBorder(),
              ),
              value: selectedName,
              items: voices.map((v) {
                final name = (v['name'] ?? 'Voz').toString();
                final locale = (v['locale'] ?? '').toString();
                return DropdownMenuItem(
                  value: name,
                  child: Text('$name${locale.isNotEmpty ? ' — $locale' : ''}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedName = val),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _play,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Ouvir amostra'),
            ),
            const SizedBox(height: 8),
            const Text('Dica: ative vozes extras nas Configurações do Android → Texto‑para‑fala'),
          ],
        ),
      ),
    );
  }
}
