import 'dart:math';
import '../models/validation_model.dart';

class ValidationService {
  Future<ValidationModel> validateTitle({
    required String ticketId,
    required String type,
    required int remainingUses,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final isValid = remainingUses > 0 && random.nextBool();

    return ValidationModel(
      id: "VAL${random.nextInt(999999)}",
      ticketId: ticketId,
      type: type,
      date: DateTime.now(),
      line: "L18",
      busId: "BUS02",
      isValid: isValid,
      message: isValid 
          ? "Viaje validado correctamente" 
          : remainingUses <= 0 
              ? "Sin viajes disponibles" 
              : "Título no válido",
    );
  }
}