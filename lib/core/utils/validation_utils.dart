/// Utilitaires de validation pour l'application.
class ValidationUtils {
  /// Valide le numéro de téléphone selon l'opérateur choisi (OM ou MoMo).
  /// Les préfixes valides pour Orange Money (OM) : 69, 640, 658, 659.
  /// Les préfixes valides pour MTN Mobile Money (MoMo) : 68, 650-657, 67.
  static bool isValidPhoneNumber(String numero, String operateur) {
    // Supprimer les espaces éventuels
    final cleanNum = numero.replaceAll(' ', '');
    
    // Doit avoir exactement 9 chiffres
    if (cleanNum.length != 9 || !RegExp(r'^[0-9]+$').hasMatch(cleanNum)) {
      return false;
    }

    if (operateur.toUpperCase() == 'OM') {
      // Préfixes OM : 69X, 640, 658, 659
      if (cleanNum.startsWith('69')) return true;
      if (cleanNum.startsWith('640')) return true;
      if (cleanNum.startsWith('658')) return true;
      if (cleanNum.startsWith('659')) return true;
    } else if (operateur.toUpperCase() == 'MOMO') {
      // Préfixes MoMo : 68X, 650-657, 67X
      if (cleanNum.startsWith('68')) return true;
      if (cleanNum.startsWith('67')) return true;
      
      // 650 à 657
      final prefix3 = int.tryParse(cleanNum.substring(0, 3));
      if (prefix3 != null && prefix3 >= 650 && prefix3 <= 657) {
        return true;
      }
    }

    return false;
  }
}
