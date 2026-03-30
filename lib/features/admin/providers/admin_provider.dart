import 'package:flutter/material.dart';
import '../../../core/services/admin_service.dart';

/// État et actions « administrateur » (validation, agents, rapports).
class AdminProvider extends ChangeNotifier {
  AdminProvider({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  final AdminService _adminService;

  Map<String, dynamic>? _dashboard;
  List<dynamic> _clientsAttente = [];
  List<dynamic> _agents = [];
  Map<String, dynamic>? _rapports;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get dashboard => _dashboard;
  List<dynamic> get clientsAttente => _clientsAttente;
  List<dynamic> get agents => _agents;
  Map<String, dynamic>? get rapports => _rapports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _dashboard?['total_clients_en_attente'] ?? 0;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _adminService.getDashboard();
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadClientsAttente() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clientsAttente = await _adminService.getClientsAttente();
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validerClient(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ok = await _adminService.validerClient(id);
      if (ok) {
        await loadClientsAttente();
        await loadDashboard(); // Pour rafraîchir le badge
        return true;
      }
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> rejeterClient(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ok = await _adminService.rejeterClient(id);
      if (ok) {
        await loadClientsAttente();
        await loadDashboard();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> loadAgents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _agents = await _adminService.getAgents();
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> creerAgent(Map<String, dynamic> agentData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _adminService.creerAgent(agentData);
      if (ok) {
        await loadAgents();
        await loadDashboard();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> toggleAgentStatut(int id, String currentStatut) async {
    final newStatut = currentStatut == 'actif' ? 'inactif' : 'actif';
    _isLoading = true;
    notifyListeners();

    try {
      final ok = await _adminService.modifierStatutAgent(id, newStatut);
      if (ok) {
        await loadAgents();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> loadRapports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rapports = await _adminService.getRapports();
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
