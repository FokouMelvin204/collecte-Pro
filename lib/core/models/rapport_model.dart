/// Rapport généré par un administrateur.
class RapportModel {
  const RapportModel({
    this.id,
    required this.dateGeneration,
    required this.typeRapport,
    required this.montantTotal,
  });

  final int? id;
  final DateTime dateGeneration;
  final String typeRapport;
  final double montantTotal;

  factory RapportModel.fromJson(Map<String, dynamic> json) {
    return RapportModel(
      id: json['id'] as int?,
      dateGeneration:
          DateTime.tryParse(json['date_generation'] as String? ?? '') ?? DateTime.now(),
      typeRapport: json['type_rapport'] as String? ?? json['typeRapport'] as String? ?? '',
      montantTotal: _parseDouble(json['montant_total'] ?? json['montantTotal']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date_generation': dateGeneration.toIso8601String(),
        'type_rapport': typeRapport,
        'montant_total': montantTotal,
      };

  static double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
