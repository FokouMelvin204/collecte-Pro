import 'package:flutter/material.dart';

/// Modèle pour un client parrainé par un agent.
class ClientModel {
  const ClientModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.statutCompte,
    this.numeroCompte,
    this.solde = 0.0,
    required this.dateInscription,
  });

  final int id;
  final String nom;
  final String email;
  final String telephone;
  final String statutCompte; // 'en_attente', 'actif', 'rejete'
  final String? numeroCompte;
  final double solde;
  final String dateInscription;

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as int? ?? 0,
      nom: json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      statutCompte: json['statut_compte']?.toString() ?? 'en_attente',
      numeroCompte: json['numero_compte']?.toString(),
      solde: _toDouble(json['solde']),
      dateInscription: json['date_inscription']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Couleur associée au statut du compte.
  Color get statutColor {
    switch (statutCompte.toLowerCase()) {
      case 'actif':
        return Colors.green;
      case 'en_attente':
        return Colors.orange;
      case 'rejete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Label lisible du statut.
  String get statutLabel {
    switch (statutCompte.toLowerCase()) {
      case 'actif':
        return 'Actif';
      case 'en_attente':
        return 'En attente';
      case 'rejete':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  /// Initiales du client pour l'avatar.
  String get initiales {
    final parts = nom.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }
}
