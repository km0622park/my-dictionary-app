import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity_dictionary/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    final service = ApiService();

    test('searchEnglish returns dummy data by default for now', () async {
      // Since we don't have a key and aren't mocking HTTP in this basic test,
      // we expect the dummy fallback.
      final result = await service.searchEnglish("good");
      expect(result.meanings.isNotEmpty, true);
      expect(result.meanings.first.def, contains("(Demo)"));
    });

    test('searchKorean returns dummy data by default', () async {
      final result = await service.searchKorean("사랑");
      expect(result.engEquivalents.isNotEmpty, true);
      expect(result.korDefinition, contains("데모 데이터"));
    });
  });
}
