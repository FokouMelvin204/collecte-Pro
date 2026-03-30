import 'user_model.dart';

/// Agent : utilisateur + code d’affiliation.
class AgentModel extends UserModel {
  const AgentModel({
    super.id,
    required super.nom,
    required super.email,
    required super.telephone,
    required super.role,
    super.motDePasse,
    required this.codeAffiliation,
  });

  final String codeAffiliation;

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] as int?,
      nom: json['nom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      role: json['role'] as String? ?? 'agent',
      motDePasse: json['mot_de_passe'] as String? ?? json['motDePasse'] as String?,
      codeAffiliation: json['code_affiliation'] as String? ?? json['codeAffiliation'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'code_affiliation': codeAffiliation,
      };
}
