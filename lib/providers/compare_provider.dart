import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';

class CompareProvider with ChangeNotifier {
  final LocalStorageService _storage;
  List<String> _compareList = [];

  CompareProvider(this._storage) {
    _loadCompareList();
  }

  List<String> get compareList => _compareList;

  Future<void> _loadCompareList() async {
    _compareList = await _storage.getCompareList();
    notifyListeners();
  }

  Future<void> addToCompare(String propertyId) async {
      await _storage.addToCompare(propertyId);
    await _loadCompareList();
  }

  Future<void> removeFromCompare(String propertyId) async {
      await _storage.removeFromCompare(propertyId);
    await _loadCompareList();
    }

  Future<void> clearCompare() async {
    await _storage.clearCompareList();
    await _loadCompareList();
  }

  bool isInCompare(String propertyId) {
    return _compareList.contains(propertyId);
  }

  bool canAddMore() {
    return _compareList.length < 3;
  }
} 