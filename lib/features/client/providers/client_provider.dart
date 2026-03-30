import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/models/dashboard_client_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/client_service.dart';

/// État et actions « client » (inscription, dashboard, versements).
class ClientProvider extends ChangeNotifier {
  ClientProvider({ClientService? clientService})
      : _clientService = clientService ?? ClientService();

  final ClientService _clientService;

  final ImagePicker _picker = ImagePicker();

  // Inscription
  XFile? _cniFile;
  Uint8List? _cniWebBytes;
  String? _cniWebName;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Dashboard
  DashboardClientModel? _dashboard;
  List<TransactionModel> _historique = [];
  double _totalVerse = 0;
  int _nombreTransactions = 0;
  bool _isLoading = false;
  bool _isVersementLoading = false;
  String? _versementSuccessMessage;

  // Getters inscription
  XFile? get cniFile => _cniFile;
  Uint8List? get cniWebBytes => _cniWebBytes;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // Getters dashboard
  DashboardClientModel? get dashboard => _dashboard;
  List<TransactionModel> get historique => _historique;
  double get totalVerse => _totalVerse;
  int get nombreTransactions => _nombreTransactions;
  bool get isLoading => _isLoading;
  bool get isVersementLoading => _isVersementLoading;
  String? get versementSuccessMessage => _versementSuccessMessage;

  // ─── Inscription ─────────────────────────────────────
  Future<void> pickCniImage({ImageSource source = ImageSource.gallery}) async {
    if (kIsWeb) {
      final x = await _picker.pickImage(source: source, imageQuality: 85);
      if (x != null) {
        _cniWebBytes = await x.readAsBytes();
        _cniWebName = x.name;
        notifyListeners();
      }
    } else {
      final x = await _picker.pickImage(source: source, imageQuality: 85);
      _cniFile = x;
      notifyListeners();
    }
  }

  void clearCni() {
    _cniFile = null;
    _cniWebBytes = null;
    _cniWebName = null;
    notifyListeners();
  }

  Future<bool> register({
    required String nom,
    required String email,
    required String telephone,
    required String motDePasse,
    String? codeAffiliation,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/client/inscription');
      final request = http.MultipartRequest('POST', uri);

      request.fields['nom'] = nom;
      request.fields['email'] = email;
      request.fields['telephone'] = telephone;
      request.fields['mot_de_passe'] = motDePasse;
      if (codeAffiliation != null && codeAffiliation.isNotEmpty) {
        request.fields['code_affiliation'] = codeAffiliation;
      }

      if (kIsWeb && _cniWebBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'cni_image',
            _cniWebBytes!,
            filename: _cniWebName ?? 'cni.jpg',
          ),
        );
      } else if (!kIsWeb && _cniFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('cni_image', _cniFile!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return true;
        } else {
          _errorMessage = data['message'] as String? ?? 'Erreur inconnue';
        }
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = (data['errors'] as List?)?.join(', ') ?? 'Champs invalides';
        _errorMessage = errors;
      } else if (response.statusCode == 409) {
        _errorMessage = 'Cet email est déjà utilisé';
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage = data['message'] as String? ?? 'Code agent invalide';
      } else {
        _errorMessage = 'Erreur serveur (${response.statusCode})';
      }

      return false;
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─── Dashboard ───────────────────────────────────────
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _clientService.getDashboard();
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> effectuerVersement(double montant) async {
    _isVersementLoading = true;
    _versementSuccessMessage = null;
    notifyListeners();

    try {
      final result = await _clientService.effectuerVersement(montant);
      final data = result['data'] as Map<String, dynamic>?;
      
      if (data != null) {
        _versementSuccessMessage = result['message'] as String?;
        // Mettre à jour le solde localement
        if (_dashboard != null) {
          _dashboard = DashboardClientModel(
            nom: _dashboard!.nom,
            email: _dashboard!.email,
            telephone: _dashboard!.telephone,
            statutCompte: _dashboard!.statutCompte,
            numeroCompte: _dashboard!.numeroCompte,
            solde: data['nouveau_solde'] as double,
            dateInscription: _dashboard!.dateInscription,
            dernieresTransactions: _dashboard!.dernieresTransactions,
          );
        }
      }
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isVersementLoading = false;
      notifyListeners();
    }
  }

  /// Simulation d'un versement réussi localement (sans API réelle).
  Future<void> simulerVersement({
    required double montant,
    required String operateur,
    required String numeroPaiement,
  }) async {
    _isVersementLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulation d'un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    if (_dashboard != null) {
      // 1. Nouveau solde
      final nouveauSolde = _dashboard!.solde + montant;

      // 2. Création d'une transaction fictive
      final newTransaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch,
        montant: montant,
        date: DateTime.now().toString().split('.')[0], // Format simple
        statut: 'success',
        typePaiement: 'depot',
        operateur: operateur,
        numeroPaiement: numeroPaiement,
      );

      // 3. Mise à jour du dashboard
      final list = List<TransactionModel>.from(_dashboard!.dernieresTransactions);
      list.insert(0, newTransaction); // Ajouter en haut de la liste

      _dashboard = DashboardClientModel(
        nom: _dashboard!.nom,
        email: _dashboard!.email,
        telephone: _dashboard!.telephone,
        statutCompte: _dashboard!.statutCompte,
        numeroCompte: _dashboard!.numeroCompte,
        solde: nouveauSolde,
        dateInscription: _dashboard!.dateInscription,
        dernieresTransactions: list,
      );

      // Mettre à jour l'historique global si chargé
      if (_historique.isNotEmpty) {
        _historique.insert(0, newTransaction);
        _totalVerse += montant;
        _nombreTransactions += 1;
      }
    }

    _isVersementLoading = false;
    notifyListeners();
  }

  Future<void> loadHistorique() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _clientService.getHistorique();
      final data = result['data'] as Map<String, dynamic>?;
      
      if (data != null) {
        final transactions = (data['transactions'] as List?)
                ?.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
        _historique = transactions;
        _totalVerse = (data['total_verse'] as num?)?.toDouble() ?? 0;
        _nombreTransactions = data['nombre_transactions'] as int? ?? 0;
      }
    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _versementSuccessMessage = null;
    notifyListeners();
  }

  void clear() {
    _dashboard = null;
    _historique = [];
    _totalVerse = 0;
    _nombreTransactions = 0;
    _errorMessage = null;
    _versementSuccessMessage = null;
    notifyListeners();
  }
}
