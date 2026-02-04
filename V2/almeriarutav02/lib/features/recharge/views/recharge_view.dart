import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recharge_viewmodel.dart';
import '../models/transport_card_model.dart';
import '../../../core/theme/app_theme.dart';

class RechargeView extends StatelessWidget {
  const RechargeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RechargeViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Tarjetas'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Consumer<RechargeViewModel>(
          builder: (_, vm, __) {
            return Column(
              children: [
                if (vm.expiringSoon.isNotEmpty) _ExpirationWarning(vm),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: vm.myCards.length,
                    itemBuilder: (_, i) {
                      final card = vm.myCards[i];
                      final expired = vm.isExpired(card);

                      return Card(
                        color: expired ? Colors.grey[300] : null,
                        child: ListTile(
                          leading: Icon(
                            Icons.credit_card,
                            color: expired ? Colors.grey : AppTheme.primaryRed,
                          ),
                          title: Text(card.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Saldo: ${card.balance.toStringAsFixed(2)} €'),
                              if (card.expirationDate != null)
                                Text(
                                  'Caduca: ${_format(card.expirationDate!)}',
                                  style: TextStyle(
                                    color: expired ? Colors.red : Colors.grey[700],
                                  ),
                                ),
                              if (card.history.isNotEmpty)
                                Text(
                                  'Recargas: ${card.history.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vm.canRecharge(card) ? AppTheme.primaryRed : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: vm.canRecharge(card)
                                ? () => _showRechargeDialog(context, vm, card)
                                : null,
                            child: const Text('Recargar'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ExpirationWarning(RechargeViewModel vm) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Próximas a caducar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...vm.expiringSoon.map((card) {
            return Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                '${card.name} - ${_format(card.expirationDate!)}',
                style: TextStyle(color: Colors.orange[700]),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showRechargeDialog(BuildContext context, RechargeViewModel vm, card) {
    if (card.type == CardType.single) {
      final controller = TextEditingController();
      
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Recargar saldo'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Importe (€)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
                onPressed: () {
                  final amount = double.tryParse(controller.text) ?? 0;
                  if (amount > 0) {
                    vm.rechargeCard(card, amount);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saldo recargado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      final amount = vm.getRechargeAmount(card);
      
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Renovar ${card.name}'),
            content: Text('Importe: ${amount.toStringAsFixed(2)} €'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
                onPressed: () {
                  vm.rechargeCard(card, amount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarjeta renovada con éxito'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  String _format(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}