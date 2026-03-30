import 'transaction_model.dart';

/// Modèle pour le dashboard client.
class DashboardClientModel {
  const DashboardClientModel({
    required this.nom,
    required this.email,
    required this.telephone,
    required this.statutCompte,
    this.numeroCompte,
    required this.solde,
    required this.dateInscription,
    required this.dernieresTransactions,
  });

  final String nom;
  final String email;
  final String telephone;
  final String statutCompte; // 'actif', 'en_attente', 'rejete'
  final String? numeroCompte;
  final double solde;
  final String dateInscription;
  final List<TransactionModel> dernieresTransactions;

  factory DashboardClientModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final transactions = (data['dernieres_transactions'] as List?)
            ?.map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [];

    return DashboardClientModel(
      nom: data['nom']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      telephone: data['telephone']?.toString() ?? '',
      statutCompte: data['statut_compte']?.toString() ?? 'en_attente',
      numeroCompte: data['numero_compte']?.toString(),
      solde: _toDouble(data['solde']),
      dateInscription: data['date_inscription']?.toString() ?? '',
      dernieresTransactions: transactions,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Couleur du statut du compte.
  String get statutColorHex {
    switch (statutCompte.toLowerCase()) {
      case 'actif':
        return '#4CAF50';
      case 'en_attente':
        return '#FF9800';
      case 'rejete':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  /// Label lisible du statut.
  String get statutLabel {
    switch (statutCompte.toLowerCase()) {
      case 'actif':
        return 'Compte Actif';
      case 'en_attente':
        return 'En attente de validation';
      case 'rejete':
        return 'Compte Rejeté';
      default:
        return 'Inconnu';
    }
  }
}
