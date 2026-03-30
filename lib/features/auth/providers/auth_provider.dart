import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';

/// État global d’authentification (UI → [AuthService] uniquement).
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService}) : _auth = authService ?? AuthService();

  final AuthService _auth;

  bool _isLoading = true;
  bool _loginInProgress = false;
  bool _isLoggedIn = false;
  String? _role;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  /// Chargement initial de session ([AuthGate] / splash).
  bool get isLoading => _isLoading;

  /// Requête de connexion en cours (bouton sur [LoginScreen]).
  bool get loginInProgress => _loginInProgress;
  bool get isLoggedIn => _isLoggedIn;
  String? get role => _role;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  int? get userId => _currentUser?['id'] as int?;

  /// Au démarrage ou depuis [AuthGate] : recharge la session locale (sans HTTP).
  Future<void> checkSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final snap = await _auth.loadSessionFromStorage();
    _isLoggedIn = snap.isLoggedIn;
    _role = snap.role;
    _currentUser = snap.currentUser;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    _loginInProgress = true;
    notifyListeners();

    final result = await _auth.login(email: email, password: password);

    if (!result.ok) {
      _errorMessage = result.message;
      _loginInProgress = false;
      notifyListeners();
      return false;
    }

    final snap = await _auth.loadSessionFromStorage();
    _isLoggedIn = snap.isLoggedIn;
    _role = snap.role;
    _currentUser = snap.currentUser;

    _loginInProgress = false;
    notifyListeners();
    return true;
  }

  Future<void> logout(BuildContext context) async {
    await _auth.logout();
    _clearState();
    notifyListeners();

    if (context.mounted) {
      // Chaîne littérale pour éviter l’import circulaire router ↔ provider.
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  void _clearState() {
    _isLoggedIn = false;
    _role = null;
    _currentUser = null;
    _errorMessage = null;
  }

  bool hasRole(String expected) {
    final r = _role;
    if (r == null) return false;
    return r == expected;
  }

  bool get isAgent => hasRole(AppStrings.roleAgent);
  bool get isClient => hasRole(AppStrings.roleClient);
  bool get isAdmin => hasRole(AppStrings.roleAdmin);

  void forceLogout() {
    _clearState();
    notifyListeners();
  }
}
