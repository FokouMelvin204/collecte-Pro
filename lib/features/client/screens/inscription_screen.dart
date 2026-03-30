import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/client_provider.dart';

/// Inscription client avec code de parrainage (via URL ?ref=).
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _codeAffiliation = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _refCodeFromUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Lire le paramètre ?ref= de l'URL (Flutter Web)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        final fullUrl = Uri.base.toString();
        debugPrint('--- DEBUG URL FULL ---');
        debugPrint('Full URL: $fullUrl');
        
        String? ref;
        
        // Méthode 1 : Uri.base (Standard)
        ref = Uri.base.queryParameters['ref'];
        
        // Méthode 2 : Analyse manuelle de la chaîne (Sécurité si HashRouter)
        if (ref == null || ref.isEmpty) {
          if (fullUrl.contains('ref=')) {
            final parts = fullUrl.split('ref=');
            if (parts.length > 1) {
              // On prend ce qui suit ref= et on s'arrête au prochain & ou à la fin
              ref = parts[1].split('&')[0];
            }
          }
        }
        
        debugPrint('Detected Ref: $ref');
        
        if (ref != null && ref.isNotEmpty) {
          setState(() {
            _refCodeFromUrl = ref;
            _codeAffiliation.text = ref!;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nom.dispose();
    _email.dispose();
    _telephone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _codeAffiliation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<ClientProvider>();
    
    final success = await provider.register(
      nom: _nom.text.trim(),
      email: _email.text.trim(),
      telephone: _telephone.text.trim(),
      motDePasse: _password.text,
      codeAffiliation: _codeAffiliation.text.trim().isEmpty ? null : _codeAffiliation.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inscription réussie'),
          content: const Text(
            'Votre demande a été soumise. Un administrateur va la valider dans les plus brefs délais.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Retour au login
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erreur lors de l\'inscription'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRefCode = _refCodeFromUrl != null && _refCodeFromUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(AppStrings.inscriptionTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'logocollectpro.png',
                  height: 120, // Taille proportionnelle
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // BANDEAU VERT SI CODE PARRAINAGE
              if (hasRefCode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vous êtes parrainé',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Code agent : $_refCodeFromUrl',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasRefCode) const SizedBox(height: 20),

              // CHAMPS DU FORMULAIRE
              AppInput(
                controller: _nom,
                label: 'Nom complet',
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Le nom est requis';
                  if (v.trim().length < 3) return 'Au moins 3 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _email,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'L\'e-mail est requis';
                  if (!v.contains('@')) return 'E-mail invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _telephone,
                label: 'Téléphone',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Le téléphone est requis';
                  if (v.trim().length < 9) return 'Numéro invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // CODE AGENT (OBLIGATOIRE)
              AppInput(
                controller: _codeAffiliation,
                label: 'Code Agent Parrain',
                prefixIcon: Icons.qr_code,
                hint: 'Ex: EE-AKWA-001',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Le code parrain est obligatoire';
                  if (!v.startsWith('EE-AKWA-')) return 'Format invalide (Ex: EE-AKWA-001)';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              AppInput(
                controller: _password,
                label: 'Mot de passe',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Le mot de passe est requis';
                  if (v.length < 6) return 'Au moins 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _confirmPassword,
                label: 'Confirmer le mot de passe',
                obscureText: _obscureConfirmPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirmez le mot de passe';
                  if (v != _password.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // BOUTON SOUMISSION
              AppButton(
                label: 'S\'inscrire',
                icon: Icons.person_add,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 16),

              // FOOTER
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Déjà un compte ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
