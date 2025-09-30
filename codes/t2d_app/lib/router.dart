import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/homepage.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/twin_page.dart';
import 'pages/gemini_page.dart';


GoRouter buildRouter() {
  final auth = Supabase.instance.client.auth;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStreamListenable(auth.onAuthStateChange),
    redirect: (context, state) {
      final isAuthed = auth.currentSession != null;
      final atAuth = state.matchedLocation == '/login' ||
                     state.matchedLocation == '/signup';

      // Guard model + gemini pages
      if (!isAuthed &&
          (state.matchedLocation.startsWith('/twin') ||
           state.matchedLocation.startsWith('/gemini'))) {
        return '/login';
      }

      // If already authed, keep you out of /login and /signup
      if (isAuthed && atAuth) return '/twin';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Homepage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/twin', builder: (_, __) => const TwinPage()),
      GoRoute(path: '/gemini', builder: (_, __) => const GeminiPage()), // ← add this
    ],
  );
}

class _AuthStreamListenable extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;
  _AuthStreamListenable(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

