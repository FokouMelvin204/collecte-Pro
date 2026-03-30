/// Modèle utilisateur de base (aligné table `utilisateurs`).
class UserModel {
  const UserModel({
    this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.role,
    this.motDePasse,
  });

  final int? id;
  final String nom;
  final String email;
  final String telephone;

  /// Valeurs attendues : `agent` | `client` | `administrateur`
  final String role;

  /// Mot de passe (souvent absent côté client après inscription).
  final String? motDePasse;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      nom: json['nom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      motDePasse: json['mot_de_passe'] as String? ?? json['motDePasse'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'role': role,
        if (motDePasse != null) 'mot_de_passe': motDePasse,
      };

  UserModel copyWith({
    int? id,
    String? nom,
    String? email,
    String? telephone,
    String? role,
    String? motDePasse,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      motDePasse: motDePasse ?? this.motDePasse,
    );
  }
}
