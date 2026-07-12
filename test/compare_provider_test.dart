import 'package:domify/providers/compare_provider.dart';
import 'package:domify/services/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('compare list is capped at two properties', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final CompareProvider provider = CompareProvider(LocalStorageService(prefs));
    await Future<void>.delayed(Duration.zero);

    await provider.addToCompare('property-1');
    await provider.addToCompare('property-2');
    await provider.addToCompare('property-3');

    expect(provider.compareList, <String>['property-1', 'property-2']);
    expect(provider.canAddMore(), isFalse);
  });

  test('existing compare item can be removed after the cap is reached', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final CompareProvider provider = CompareProvider(LocalStorageService(prefs));
    await Future<void>.delayed(Duration.zero);

    await provider.addToCompare('property-1');
    await provider.addToCompare('property-2');
    await provider.removeFromCompare('property-1');

    expect(provider.compareList, <String>['property-2']);
    expect(provider.canAddMore(), isTrue);
  });
}
