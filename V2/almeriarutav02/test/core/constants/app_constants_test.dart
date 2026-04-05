import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('defines stable app and api identifiers', () {
      expect(AppConstants.appName, isNotEmpty);
      expect(AppConstants.appName, contains('AlmeriaRuta'));

      expect(AppConstants.apiBaseUrl, startsWith('http://'));
      expect(AppConstants.authApiBaseUrl, startsWith('http://'));
      expect(AppConstants.apiBaseUrl, contains('10.0.2.2'));
      expect(AppConstants.authApiBaseUrl, contains('10.0.2.2'));
      expect(AppConstants.apiBaseUrl, isNot(AppConstants.authApiBaseUrl));
    });
  });
}
