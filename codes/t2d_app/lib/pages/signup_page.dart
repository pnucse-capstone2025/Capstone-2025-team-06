import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _busy = false;
  String? _err;
  String? _info;

  Future<void> _signup() async {
    setState(() { _busy = true; _err = null; _info = null; });
    try {
      if (_pw.text != _pw2.text) { setState(() => _err = 'Passwords do not match'); return; }
      final res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(), password: _pw.text.trim());
      if (res.session == null) { setState(() => _info = 'Check your email to confirm.'); }
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } catch (e) {
      setState(() => _err = 'Unexpected error: $e');
    } finally { setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Sign up', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: _pw, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 12),
                TextField(controller: _pw2, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password')),
                const SizedBox(height: 12),
                if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
                if (_info != null) Text(_info!, style: const TextStyle(color: Colors.orange)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _busy ? null : _signup, child: const Text('Create account')),
                TextButton(onPressed: _busy ? null : () => context.go('/login'),
                    child: const Text('Have an account? Sign in')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
