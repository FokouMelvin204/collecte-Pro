import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/client_provider.dart';
import '../../../core/models/transaction_model.dart';

/// Historique des transactions client.
class HistoriqueScreen extends StatefulWidget {
  final bool isEmbedded;
  const HistoriqueScreen({super.key, this.isEmbedded = false});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadHistorique();
    });
  }

  String _formatMontant(double montant) {
    final parts = montant.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return parts;
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final jour = d.day.toString().padLeft(2, '0');
      final mois = d.month.toString().padLeft(2, '0');
      final heure = d.hour.toString().padLeft(2, '0');
      final minute = d.minute.toString().padLeft(2, '0');
      return '$jour/$mois/$d.year à ${heure}h$minute';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEmbedded 
          ? null 
          : AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: const Text('Historique des transactions'),
            ),
      body: Consumer<ClientProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.historique.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return Column(
            children: [
              // Carte récap en haut
              Container(
                width: double.infinity,
                color: const Color(0xFF1B8A3A),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total versé',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatMontant(provider.totalVerse)} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Transactions',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.nombreTransactions}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Liste complète
              Expanded(
                child: provider.historique.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune transaction',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: provider.historique.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final t = provider.historique[i];
                          return _TransactionTile(
                            transaction: t,
                            formatMontant: _formatMontant,
                            formatDate: _formatDate,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(double) formatMontant;
  final String Function(String) formatDate;

  const _TransactionTile({
    required this.transaction,
    required this.formatMontant,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.green[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          transaction.typeIcon,
          color: transaction.typeColor,
        ),
      ),
      title: Text(
        'Versement',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        formatDate(transaction.date),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '+${formatMontant(transaction.montant)} FCFA',
            style: const TextStyle(
              color: Color(0xFF1B8A3A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: transaction.statutColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              transaction.statutLabel,
              style: TextStyle(
                fontSize: 10,
                color: transaction.statutColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
