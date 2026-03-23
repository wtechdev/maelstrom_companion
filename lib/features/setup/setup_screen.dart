import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/frosted_container.dart';
import '../../shared/widgets/wtech_logo.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errore;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _caricaUrlSalvato();
  }

  Future<void> _caricaUrlSalvato() async {
    final storage = ref.read(tokenStorageProvider);
    final url = await storage.getUrl();
    if (mounted) {
      _urlController.text = url ?? 'http://localhost:8080';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connetti() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errore = null; });
    try {
      final url = _urlController.text.trim().replaceAll(RegExp(r'/$'), '');
      final risposta = await ApiClient.login(
        baseUrl: url,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final token = (risposta['data'] as Map<String, dynamic>)['token'] as String;
      final storage = ref.read(tokenStorageProvider);
      final pkgInfo = await PackageInfo.fromPlatform();
      await storage.salva(url: url, token: token, versione: pkgInfo.version);
      ref.invalidate(authStateProvider);
      ref.invalidate(apiClientProvider);
      await ref.read(authStateProvider.future);
      if (mounted) context.go('/home/projects');
    } on ApiException catch (e) {
      setState(() => _errore = e.statusCode == 401
          ? 'Email o password non validi.'
          : e.statusCode == 403
              ? 'Utente non associato a nessuna struttura.'
              : 'Errore: ${e.message}');
    } catch (e) {
      setState(() => _errore = 'Impossibile raggiungere il server.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apriImpostazioni() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ServerDialog(urlController: _urlController),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FrostedContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    const WtechLogo(height: 64),
                    const SizedBox(height: 12),
                    Text(
                      'Accedi con le tue credenziali.',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    _inputField(
                      label: 'Email',
                      controller: _emailController,
                      hint: 'nome@azienda.it',
                      keyboard: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci l\'email' : null,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      label: 'Password',
                      controller: _passwordController,
                      hint: '••••••••',
                      obscure: !_passwordVisible,
                      suffix: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Inserisci la password' : null,
                    ),
                    if (_errore != null) ...[
                      const SizedBox(height: 12),
                      Text(_errore!, style: TextStyle(color: cs.error, fontSize: 12), textAlign: TextAlign.center),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _loading ? null : _connetti,
                        child: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Accedi', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Icona impostazioni server — angolo in alto a destra
            Positioned(
              top: 28,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.dns_outlined, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                tooltip: 'Impostazioni server',
                onPressed: _apriImpostazioni,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: suffix,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

/// Dialog compatto per configurare l'URL del server.
class _ServerDialog extends StatefulWidget {
  final TextEditingController urlController;
  const _ServerDialog({required this.urlController});

  @override
  State<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<_ServerDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.urlController.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.dns_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Server', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      content: SizedBox(
        width: 300,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'http://localhost:8080',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final url = _ctrl.text.trim().replaceAll(RegExp(r'/$'), '');
            if (url.isNotEmpty) widget.urlController.text = url;
            Navigator.of(context).pop();
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
