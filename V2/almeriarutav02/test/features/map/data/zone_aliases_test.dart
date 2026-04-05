import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/map/data/zone_aliases.dart';

void main() {
  group('ZoneAliases', () {
    test('contains expected canonical mappings', () {
      expect(ZoneAliases.aliases['centro'], 'Centro');
      expect(ZoneAliases.aliases['rambla'], 'Centro');
      expect(ZoneAliases.aliases['playa'], 'Zona Playa');
      expect(ZoneAliases.aliases['hospital'], 'Zona Norte');
      expect(ZoneAliases.aliases['ual'], 'La Canada / Universidad');
      expect(ZoneAliases.aliases['aeropuerto'], 'Aeropuerto');
    });

    test('all keys are normalized to lowercase', () {
      final hasUppercaseKey = ZoneAliases.aliases.keys.any(
        (k) => k != k.toLowerCase(),
      );

      expect(hasUppercaseKey, isFalse);
    });
  });
}
