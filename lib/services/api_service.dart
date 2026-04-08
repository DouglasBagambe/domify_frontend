import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';

class ApiService {
  // Use loopback address for local development
  static const String baseUrl = 'http://127.0.0.1:3000/api'; // Localhost for same-machine connections

  // Get all properties (static method to match home screen usage)
  static Future<List<Property>> getAllProperties() async {
    try {
      print('Fetching properties from: ${Uri.parse('$baseUrl/properties')}');
      final response = await http.get(Uri.parse('$baseUrl/properties'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body.length > 500 ? response.body.substring(0, 500) + "... (truncated)" : response.body}');
      
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('properties')) {
          // Handle paginated response format
          final List<dynamic> data = responseData['properties'];
          return data.map((json) => Property.fromJson(json)).toList();
        } else if (responseData is List) {
          // Handle direct list response
          return responseData.map((json) => Property.fromJson(json)).toList();
        } else {
          print('Unexpected response format: $responseData');
          return [];
        }
      }
      throw Exception('Failed to load properties: ${response.statusCode}');
    } catch (e) {
      print('Error fetching properties: $e');
      return []; // Return empty list on error to prevent infinite loading
    }
  }

  // Get all properties (instance method for backward compatibility)
  Future<List<Property>> getProperties() async {
    return getAllProperties(); // Delegate to static method
  }

  // Get featured properties
  static Future<List<Property>> getFeaturedProperties() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/properties/featured'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      }
      throw Exception('Failed to load featured properties');
    } catch (e) {
      print('Error fetching featured properties: $e');
      return []; // Return empty list on error
    }
  }

  // Get recent properties
  static Future<List<Property>> getRecentProperties() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/properties/recent'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      }
      throw Exception('Failed to load recent properties');
    } catch (e) {
      print('Error fetching recent properties: $e');
      return []; // Return empty list on error
    }
  }

  // Get property by ID
  static Future<Property> getPropertyById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/$id'));
    if (response.statusCode == 200) {
      return Property.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load property');
    }
  }

  // Search properties
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
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search properties');
    }
  }

  // Book appointment
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
      throw Exception('Failed to book appointment');
    }
  }

  static Future<Property> getProperty(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/properties/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Property.fromJson(data);
      }
      throw Exception('Failed to load property');
    } catch (e) {
      throw Exception('Error fetching property: $e');
    }
  }

  // Admin: Add a new property
  static Future<Property> addProperty({
    required Map<String, dynamic> propertyData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(propertyData),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Property.fromJson(data);
      }
      throw Exception('Failed to add property: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding property: $e');
    }
  }

  // Admin: Update a property
  static Future<Property> updateProperty({
    required String id,
    required Map<String, dynamic> propertyData,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/properties/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(propertyData),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Property.fromJson(data);
      }
      throw Exception('Failed to update property: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating property: $e');
    }
  }

  // Admin: Delete a property
  static Future<void> deleteProperty(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/properties/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete property: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting property: $e');
    }
  }

  // Admin: Toggle featured status of a property
  static Future<Property> toggleFeaturedProperty(String id) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/properties/$id/featured'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Property.fromJson(data);
      }
      throw Exception('Failed to toggle featured status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error toggling featured status: $e');
    }
  }

  // Admin: Get appointments for a property
  static Future<List<dynamic>> getAppointmentsForProperty(String propertyId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/appointments/property/$propertyId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load appointments: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }
}