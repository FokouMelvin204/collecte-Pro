import 'package:flutter/material.dart';

/// Modèle pour une transaction client.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.montant,
    required this.date,
    required this.statut,
    required this.typePaiement,
    this.operateur,
    this.numeroPaiement,
  });

  final int id;
  final double montant;
  final String date;
  final String statut; // 'success', 'failed', 'pending'
  final String typePaiement; // 'depot', 'retrait', etc.
  final String? operateur;
  final String? numeroPaiement;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int? ?? 0,
      montant: _toDouble(json['montant']),
      date: json['date']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      typePaiement: json['type_paiement']?.toString() ?? 'depot',
      operateur: json['operateur']?.toString(),
      numeroPaiement: json['numero_paiement']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Couleur associée au statut.
  Color get statutColor {
    switch (statut.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// Label lisible du statut.
  String get statutLabel {
    switch (statut.toLowerCase()) {
      case 'success':
        return 'Validé';
      case 'failed':
        return 'Échoué';
      default:
        return 'En attente';
    }
  }

  /// Icône selon le type de paiement.
  IconData get typeIcon {
    return typePaiement.toLowerCase() == 'depot'
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  }

  /// Couleur de l'icône selon le type.
  Color get typeColor {
    return typePaiement.toLowerCase() == 'depot'
        ? Colors.green
        : Colors.blue;
  }
}
