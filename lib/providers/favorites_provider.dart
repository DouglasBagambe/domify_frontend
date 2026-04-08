import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _favorites = {};
  static const String _storageKey = 'favorites';

  FavoritesProvider() {
    _loadFavorites();
  }

  Set<String> get favorites => _favorites;

  bool isFavorite(String propertyId) => _favorites.contains(propertyId);

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFavorites = prefs.getStringList(_storageKey) ?? [];
    _favorites.addAll(savedFavorites);
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _favorites.toList());
  }

  Future<void> addFavorite(String propertyId) async {
    _favorites.add(propertyId);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String propertyId) async {
    _favorites.remove(propertyId);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(String propertyId) async {
    if (isFavorite(propertyId)) {
      await removeFavorite(propertyId);
    } else {
      await addFavorite(propertyId);
    }
  }

  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }
} 