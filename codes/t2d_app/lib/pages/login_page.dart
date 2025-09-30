import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _login() async {
    setState(() { _busy = true; _err = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(), password: _pw.text.trim());
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } catch (e) {
      setState(() => _err = 'Unexpected error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: _pw, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 12),
                if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _busy ? null : _login, child: const Text('Sign in')),
                TextButton(onPressed: _busy ? null : () => context.go('/signup'),
                    child: const Text("Don't have an account? Sign up")),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
