import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';
import 'api_cache.dart';

class ApiService {
  static const String baseUrl = 'https://domify.onrender.com/api';

  // ─── helpers ────────────────────────────────────────────────────────────────

  static List<Property> _parseList(String body) {
    final dynamic d = json.decode(body);
    if (d is Map && d.containsKey('properties')) {
      return (d['properties'] as List).map((j) => Property.fromJson(j)).toList();
    } else if (d is List) {
      return d.map((j) => Property.fromJson(j)).toList();
    }
    return [];
  }

  static Future<List<Property>> _cachedList(
      String cacheKey, String path, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await ApiCache.get(cacheKey);
      if (cached != null) return _parseList(cached);
    }
    final response = await http.get(Uri.parse('$baseUrl/$path'));
    if (response.statusCode == 200) {
      await ApiCache.set(cacheKey, response.body);
      return _parseList(response.body);
    }
    throw Exception('HTTP ${response.statusCode} for $path');
  }

  // ─── public API ─────────────────────────────────────────────────────────────

  static Future<List<Property>> getAllProperties({bool forceRefresh = false}) async {
    try {
      return await _cachedList('all_properties', 'properties', forceRefresh: forceRefresh);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Property>> getFeaturedProperties({bool forceRefresh = false}) async {
    try {
      return await _cachedList('featured_properties', 'properties/featured', forceRefresh: forceRefresh);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Property>> getRecentProperties({bool forceRefresh = false}) async {
    try {
      return await _cachedList('recent_properties', 'properties/recent', forceRefresh: forceRefresh);
    } catch (e) {
      return [];
    }
  }

  // instance method kept for backward-compat
  Future<List<Property>> getProperties() => getAllProperties();

  static Future<Property> getPropertyById(String id) async {
    final cached = await ApiCache.get('property_$id');
    if (cached != null) {
      return Property.fromJson(json.decode(cached));
    }

    final cachedList = await ApiCache.get('all_properties');
    if (cachedList != null) {
      Property? property;
      for (final item in _parseList(cachedList)) {
        if (item.id == id) {
          property = item;
          break;
        }
      }
      if (property != null) {
        await ApiCache.set('property_$id', json.encode(property.toJson()));
        return property;
      }
    }

    final response = await http.get(Uri.parse('$baseUrl/properties/$id'));
    if (response.statusCode == 200) {
      await ApiCache.set('property_$id', response.body);
      return Property.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load property');
  }

  static Future<Property> getProperty(String id) => getPropertyById(id);

  static Future<List<Property>> searchProperties({
    String? query,
    PropertyType? type,
    PropertyPurpose? purpose,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParams = <String, String>{};
    if (query != null) queryParams['query'] = query;
    if (type != null) queryParams['type'] = type.toString().split('.').last;
    if (purpose != null) queryParams['purpose'] = purpose.toString().split('.').last;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

    final uri = Uri.parse('$baseUrl/properties/search').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => Property.fromJson(j)).toList();
    }
    throw Exception('Failed to search properties');
  }

  static Future<void> bookAppointment({
    required String propertyId,
    required String name,
    required String phone,
    required String email,
    required DateTime appointmentTime,
    required String duration,
    required String purpose,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'propertyId': propertyId,
        'name': name,
        'phone': phone,
        'email': email,
        'appointmentTime': appointmentTime.toIso8601String(),
        'duration': duration,
        'purpose': purpose,
        if (notes != null) 'notes': notes,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to book appointment: ${response.statusCode}');
    }
  }

  static Future<Property> addProperty({required Map<String, dynamic> propertyData}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/properties'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(propertyData),
    );
    if (response.statusCode == 201) {
      await ApiCache.clear(); // invalidate lists
      return Property.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to add property: ${response.statusCode}');
  }

  static Future<Property> updateProperty({
    required String id,
    required Map<String, dynamic> propertyData,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/properties/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(propertyData),
    );
    if (response.statusCode == 200) {
      await ApiCache.invalidate('property_$id');
      await ApiCache.invalidate('all_properties');
      return Property.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update property: ${response.statusCode}');
  }

  static Future<void> deleteProperty(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/properties/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete property: ${response.statusCode}');
    }
    await ApiCache.invalidate('property_$id');
    await ApiCache.clear();
  }

  static Future<Property> toggleFeaturedProperty(String id) async {
    final response = await http.patch(Uri.parse('$baseUrl/properties/$id/featured'));
    if (response.statusCode == 200) {
      await ApiCache.invalidate('featured_properties');
      return Property.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to toggle featured status: ${response.statusCode}');
  }

  static Future<List<dynamic>> getAppointmentsForProperty(String propertyId) async {
    final response = await http.get(Uri.parse('$baseUrl/appointments/property/$propertyId'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load appointments: ${response.statusCode}');
  }
}
