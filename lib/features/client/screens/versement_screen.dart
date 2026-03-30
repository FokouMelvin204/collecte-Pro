import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validation_utils.dart';
import '../providers/client_provider.dart';

/// Écran pour effectuer un versement (Workflow Multi-étapes).
class VersementScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onNavigateToHistory;
  final VoidCallback? onNavigateToDashboard;
  
  const VersementScreen({
    super.key, 
    this.isEmbedded = false,
    this.onNavigateToHistory,
    this.onNavigateToDashboard,
  });

  @override
  State<VersementScreen> createState() => _VersementScreenState();
}

class _VersementScreenState extends State<VersementScreen> {
  // État du workflow
  int _currentStep = 1; // 1: Choix Opérateur, 2: Formulaire
  String? _selectedOperator; // 'MOMO' ou 'OM'
  
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _montantController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _montantController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _currentStep = 1;
      _selectedOperator = null;
      _phoneController.clear();
      _montantController.clear();
      _pinController.clear();
    });
  }

  void _validateAndConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final numero = _phoneController.text.trim();
    final montant = double.tryParse(_montantController.text) ?? 0;

    // Validation des préfixes
    if (!ValidationUtils.isValidPhoneNumber(numero, _selectedOperator!)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Numéro invalide'),
          content: Text('Ce numéro est invalide. Entrez un numéro ${_selectedOperator == 'OM' ? 'Orange' : 'MTN'}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Étape 3 : Boîte de dialogue de confirmation
    _showPinDialog(montant, numero);
  }

  void _showPinDialog(double montant, String numero) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirmez la transaction en entrant votre code secret, ou tapez 2 pour annuler.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'XXXX',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pinController.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.length == 4) {
                Navigator.pop(ctx);
                _executeTransaction(montant, numero);
              } else if (_pinController.text == '2') {
                _pinController.clear();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B8A3A)),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _executeTransaction(double montant, String numero) async {
    final provider = context.read<ClientProvider>();
    
    // Simuler le versement
    await provider.simulerVersement(
      montant: montant,
      operateur: _selectedOperator!,
      numeroPaiement: numero,
    );

    if (!mounted) return;

    // Étape 4 : Succès
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Succès'),
          ],
        ),
        content: const Text('Votre paiement a été effectué avec succès.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
              if (widget.onNavigateToDashboard != null) {
                widget.onNavigateToDashboard!();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatMontant(double montant) {
    return montant.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isEmbedded 
          ? null 
          : AppBar(
              backgroundColor: const Color(0xFF1B8A3A),
              foregroundColor: Colors.white,
              title: const Text('Faire un versement'),
              leading: _currentStep == 2 
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _currentStep = 1),
                    )
                  : null,
            ),
      body: _currentStep == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre mode de paiement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildOperatorCard(
            label: 'MTN Mobile Money',
            logo: 'logoMOMO.png',
            onTap: () => setState(() {
              _selectedOperator = 'MOMO';
              _currentStep = 2;
            }),
          ),
          const SizedBox(height: 16),
          _buildOperatorCard(
            label: 'Orange Money',
            logo: 'logoOM.png',
            onTap: () => setState(() {
              _selectedOperator = 'OM';
              _currentStep = 2;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorCard({required String label, required String logo, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Image.asset(logo, width: 60, height: 60, errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 60)),
            const SizedBox(width: 20),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _currentStep = 1),
                ),
                Image.asset(
                  _selectedOperator == 'OM' ? 'logoOM.png' : 'logoMOMO.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => const Icon(Icons.payment),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedOperator == 'OM' ? 'Orange Money' : 'MTN MoMo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de paiement',
                hintText: 'Ex: 6XXXXXXXX',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Le numéro est requis';
                if (v.replaceAll(' ', '').length != 9) return 'Le numéro doit avoir 9 chiffres';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Le montant est requis';
                final m = double.tryParse(v);
                if (m == null || m <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Consumer<ClientProvider>(
                builder: (context, provider, _) => ElevatedButton(
                  onPressed: provider.isVersementLoading ? null : _validateAndConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A3A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: provider.isVersementLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Valider', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
