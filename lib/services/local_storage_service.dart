import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_model.dart';

class LocalStorageService {
  static const String _favoritesKey = 'favorites';
  static const String _compareKey = 'compare';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Favorites
  Future<List<String>> getFavorites() async {
    final String? favoritesJson = _prefs.getString(_favoritesKey);
    if (favoritesJson == null) return [];
    return List<String>.from(json.decode(favoritesJson));
  }

  Future<void> addToFavorites(String propertyId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(propertyId)) {
      favorites.add(propertyId);
      await _prefs.setString(_favoritesKey, json.encode(favorites));
    }
  }

  Future<void> removeFromFavorites(String propertyId) async {
    final favorites = await getFavorites();
    favorites.remove(propertyId);
    await _prefs.setString(_favoritesKey, json.encode(favorites));
  }

  // Compare
  Future<List<String>> getCompareList() async {
    final String? compareJson = _prefs.getString(_compareKey);
    if (compareJson == null) return [];
    return List<String>.from(json.decode(compareJson));
  }

  Future<void> addToCompare(String propertyId) async {
    final compareList = await getCompareList();
    if (compareList.length < 3 && !compareList.contains(propertyId)) {
      compareList.add(propertyId);
      await _prefs.setString(_compareKey, json.encode(compareList));
    }
  }

  Future<void> removeFromCompare(String propertyId) async {
    final compareList = await getCompareList();
    compareList.remove(propertyId);
    await _prefs.setString(_compareKey, json.encode(compareList));
  }

  Future<void> clearCompareList() async {
    await _prefs.remove(_compareKey);
  }

  // Recent Searches
  Future<List<String>> getRecentSearches() async {
    final String? searchesJson = _prefs.getString(_recentSearchesKey);
    if (searchesJson == null) return [];
    return List<String>.from(json.decode(searchesJson));
  }

  Future<void> addRecentSearch(String search) async {
    final searches = await getRecentSearches();
    searches.remove(search); // Remove if exists
    searches.insert(0, search); // Add to beginning
    if (searches.length > 10) searches.removeLast(); // Keep only last 10
    await _prefs.setString(_recentSearchesKey, json.encode(searches));
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }

  // Onboarding
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(_onboardingCompletedKey, true);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }
} 