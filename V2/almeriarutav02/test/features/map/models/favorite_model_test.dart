import 'package:flutter_test/flutter_test.dart';
import 'package:almeriarutav02/features/map/models/favorite_model.dart';

void main() {
  group('FavoriteModel', () {
    test('toJson uses enum name', () {
      final favorite = FavoriteModel(
        id: '1',
        name: 'Parada Centro',
        type: FavoriteType.stop,
      );

      expect(favorite.toJson(), {
        'id': '1',
        'name': 'Parada Centro',
        'type': 'stop',
      });
    });

    test('fromJson restores enum value', () {
      final favorite = FavoriteModel.fromJson({
        'id': '2',
        'name': 'L1',
        'type': 'line',
      });

      expect(favorite.id, '2');
      expect(favorite.type, FavoriteType.line);
    });
  });
}
