import 'package:flutter/foundation.dart';

import '../../../core/models/dashboard_agent_model.dart';
import '../../../core/models/client_model.dart';
import '../../../core/models/commission_model.dart';
import '../../../core/services/agent_service.dart';
import '../../../core/services/storage_service.dart';

/// État et actions métier « agent » (dashboard, clients, commissions).
class AgentProvider extends ChangeNotifier {
  AgentProvider({AgentService? agentService}) : _agentService = agentService ?? AgentService();

  final AgentService _agentService;

  bool _isLoading = false;
  String? _errorMessage;
  
  DashboardAgentModel? _dashboard;
  List<ClientModel> _clients = [];
  List<CommissionModel> _commissions = [];
  double _totalCommissions = 0.0;
  double _tauxCommission = 2.0;
  String _codeAffiliation = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  DashboardAgentModel? get dashboard => _dashboard;
  List<ClientModel> get clients => _clients;
  List<CommissionModel> get commissions => _commissions;
  double get totalCommissions => _totalCommissions;
  double get tauxCommission => _tauxCommission;
  String get codeAffiliation => _codeAffiliation;

  int get nombreClients => _clients.length;

  /// Charge le dashboard de l'agent.
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _agentService.getDashboard();
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge la liste des clients.
  Future<void> loadClients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clients = await _agentService.getClients();
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les commissions.
  Future<void> loadCommissions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _agentService.getCommissions();
      _commissions = data.commissions;
      _totalCommissions = data.totalCommissions;
      _tauxCommission = data.taux;
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge le profil pour récupérer le code d'affiliation.
  Future<void> loadProfile() async {
    try {
      final profile = await _agentService.getProfile();
      _codeAffiliation = profile['code_affiliation']?.toString() ?? '';
      _tauxCommission = (profile['taux_commission'] is num) 
          ? (profile['taux_commission'] as num).toDouble() 
          : 2.0;
      notifyListeners();
    } catch (_) {
      // Si échec, on essaie de récupérer depuis le storage
      final storage = StorageService();
      _codeAffiliation = await storage.getString(StorageKeys.agentCodeAffiliation) ?? '';
      final taux = await storage.getDouble(StorageKeys.agentTauxCommission);
      if (taux != null) {
        _tauxCommission = taux;
      }
      notifyListeners();
    }
  }

  /// Réinitialise l'état.
  void clear() {
    _dashboard = null;
    _clients = [];
    _commissions = [];
    _totalCommissions = 0.0;
    _tauxCommission = 2.0;
    _codeAffiliation = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Efface le message d'erreur.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
