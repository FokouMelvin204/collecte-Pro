/// Modèle pour le dashboard agent.
class DashboardAgentModel {
  const DashboardAgentModel({
    required this.totalCollecteJour,
    required this.totalCollecteMois,
    required this.nombreClients,
    required this.commissionJour,
    required this.commissionMois,
    required this.versementsRecents,
  });

  final double totalCollecteJour;
  final double totalCollecteMois;
  final int nombreClients;
  final double commissionJour;
  final double commissionMois;
  final List<VersementRecentModel> versementsRecents;

  factory DashboardAgentModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final versements = (data['versements_recents'] as List?)
            ?.map((v) => VersementRecentModel.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    return DashboardAgentModel(
      totalCollecteJour: _toDouble(data['total_collecte_jour']),
      totalCollecteMois: _toDouble(data['total_collecte_mois']),
      nombreClients: data['nombre_clients'] as int? ?? 0,
      commissionJour: _toDouble(data['commission_jour']),
      commissionMois: _toDouble(data['commission_mois']),
      versementsRecents: versements,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

/// Modèle pour un versement récent.
class VersementRecentModel {
  const VersementRecentModel({
    required this.clientNom,
    required this.montant,
    required this.date,
    required this.statut,
  });

  final String clientNom;
  final double montant;
  final String date;
  final String statut;

  factory VersementRecentModel.fromJson(Map<String, dynamic> json) {
    return VersementRecentModel(
      clientNom: json['client_nom']?.toString() ?? '',
      montant: _toDouble(json['montant']),
      date: json['date']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
