/// Modèle pour une commission d'agent.
class CommissionModel {
  const CommissionModel({
    required this.id,
    required this.montant,
    required this.date,
    required this.transactionMontant,
    required this.clientNom,
  });

  final int id;
  final double montant;
  final String date;
  final double transactionMontant;
  final String clientNom;

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id: json['id'] as int? ?? 0,
      montant: _toDouble(json['montant']),
      date: json['date']?.toString() ?? '',
      transactionMontant: _toDouble(json['transaction_montant']),
      clientNom: json['client_nom']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

/// Modèle pour les données de commissions (total + liste).
class CommissionsDataModel {
  const CommissionsDataModel({
    required this.totalCommissions,
    required this.taux,
    required this.commissions,
  });

  final double totalCommissions;
  final double taux;
  final List<CommissionModel> commissions;

  factory CommissionsDataModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final commissionsList = (data['commissions'] as List?)
            ?.map((c) => CommissionModel.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    return CommissionsDataModel(
      totalCommissions: _toDouble(data['total_commissions']),
      taux: _toDouble(data['taux']),
      commissions: commissionsList,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
