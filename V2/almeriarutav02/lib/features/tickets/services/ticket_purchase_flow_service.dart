import '../../../features/tickets/models/ticket_model.dart';
import '../../../shared/services/ticket_validation_flow_service.dart';
import '../viewmodels/ticket_viewmodel.dart';
import 'ticket_purchase_api_service.dart';

class GiftPurchaseCheckResult {
  final bool needsAuth;
  final String? message;

  const GiftPurchaseCheckResult({
    required this.needsAuth,
    this.message,
  });

  bool get canProceed => !needsAuth && message == null;
}

class TicketPurchaseFlowService {
  final TicketPurchaseApiService _purchaseApi;

  TicketPurchaseFlowService({TicketPurchaseApiService? purchaseApi})
      : _purchaseApi = purchaseApi ?? TicketPurchaseApiService();

  GiftPurchaseCheckResult checkGiftPurchasePreconditions({
    required bool isGiftMode,
    required bool isAuthenticated,
    required bool isGuest,
    required String? token,
    required String recipient,
  }) {
    if (!isGiftMode) {
      return const GiftPurchaseCheckResult(needsAuth: false);
    }

    if (!isAuthenticated || isGuest || token == null) {
      return const GiftPurchaseCheckResult(
        needsAuth: true,
        message: 'Para comprar un ticket a otro usuario debes iniciar sesión o registrarte.',
      );
    }

    if (recipient.isEmpty) {
      return const GiftPurchaseCheckResult(
        needsAuth: false,
        message: 'Introduce el email o usuario del destinatario',
      );
    }

    return const GiftPurchaseCheckResult(needsAuth: false);
  }

  Future<void> validateGiftRecipient({
    required String token,
    required String recipient,
  }) {
    return _purchaseApi.validateRecipient(
      token: token,
      recipientIdentifier: recipient,
    );
  }

  Future<void> notifyGiftPurchase({
    required String token,
    required String recipient,
    required String type,
    required int quantity,
    required double amount,
    required String paymentMethod,
  }) {
    return _purchaseApi.notifyTicketPurchase(
      token: token,
      recipientIdentifier: recipient,
      type: type,
      quantity: quantity,
      amount: amount,
      paymentMethod: paymentMethod,
    );
  }

  Future<void> syncTicketAfterValidation({
    required TicketViewModel vm,
    required TicketModel ticket,
    required TicketValidationFlowResult result,
  }) async {
    if (!result.wasUsed) return;

    if (result.isExhausted) {
      await vm.useTicket(ticket.id);
      return;
    }

    await vm.persistTicketsState();
  }
}
