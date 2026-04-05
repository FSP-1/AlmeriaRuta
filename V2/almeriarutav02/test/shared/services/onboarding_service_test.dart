import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:almeriarutav02/shared/services/onboarding_service.dart';

void main() {
  group('OnboardingService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isDone returns false by default', () async {
      final done = await OnboardingService.isDone();
      expect(done, isFalse);
    });

    test('setDone persists onboarding flag', () async {
      await OnboardingService.setDone();

      final done = await OnboardingService.isDone();
      expect(done, isTrue);
    });

    test('reset clears onboarding flag', () async {
      await OnboardingService.setDone();
      await OnboardingService.reset();

      final done = await OnboardingService.isDone();
      expect(done, isFalse);
    });
  });
}
