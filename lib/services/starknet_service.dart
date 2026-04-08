import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StarknetService {
  static const String baseUrl = 'http://127.0.0.1:3000/api/starknet';
  
  // Wallet state
  String? _walletAddress;
  bool _isConnected = false;

  String? get walletAddress => _walletAddress;
  bool get isConnected => _isConnected;

  // Initialize and check for saved wallet
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _walletAddress = prefs.getString('starknet_wallet_address');
    _isConnected = _walletAddress != null;
  }

  // Connect wallet (in production, this would use Argent X or Braavos)
  Future<bool> connectWallet(String walletAddress) async {
    try {
      // Validate address format (basic check)
      if (!walletAddress.startsWith('0x') || walletAddress.length < 60) {
        throw Exception('Invalid Starknet address format');
      }

      _walletAddress = walletAddress;
      _isConnected = true;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('starknet_wallet_address', walletAddress);

      return true;
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
      return false;
    }
  }

  // Disconnect wallet
  Future<void> disconnectWallet() async {
    _walletAddress = null;
    _isConnected = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('starknet_wallet_address');
  }

  // ============ Property NFT Functions ============

  /// Mint property as NFT on Starknet
  Future<Map<String, dynamic>> mintProperty(String propertyId) async {
    if (!_isConnected || _walletAddress == null) {
      throw Exception('Wallet not connected');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties/$propertyId/mint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ownerAddress': _walletAddress,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to mint property');
      }
    } catch (e) {
      debugPrint('Error minting property: $e');
      rethrow;
    }
  }

  /// Get property blockchain details
  Future<Map<String, dynamic>> getPropertyBlockchainDetails(String propertyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/$propertyId/blockchain'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'onChain': false};
      } else {
        throw Exception('Failed to get blockchain details');
      }
    } catch (e) {
      debugPrint('Error getting blockchain details: $e');
      return {'onChain': false};
    }
  }

  // ============ Escrow Functions ============

  /// Create escrow for property booking/deposit
  Future<Map<String, dynamic>> createEscrow({
    required String propertyId,
    required double amount,
    required String escrowType, // 'booking', 'deposit', 'payment'
    String? releaseConditions,
  }) async {
    if (!_isConnected || _walletAddress == null) {
      throw Exception('Wallet not connected');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/escrow/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'propertyId': propertyId,
          'buyerAddress': _walletAddress,
          'amount': amount,
          'escrowType': escrowType,
          'releaseConditions': releaseConditions ?? 'Standard release conditions',
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create escrow');
      }
    } catch (e) {
      debugPrint('Error creating escrow: $e');
      rethrow;
    }
  }

  /// Get escrow status
  Future<Map<String, dynamic>> getEscrowStatus(String escrowId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/escrow/$escrowId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get escrow status');
      }
    } catch (e) {
      debugPrint('Error getting escrow status: $e');
      rethrow;
    }
  }

  // ============ Reputation Functions ============

  /// Register as agent on blockchain
  Future<Map<String, dynamic>> registerAgent(Map<String, dynamic> metadata) async {
    if (!_isConnected || _walletAddress == null) {
      throw Exception('Wallet not connected');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agents/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'agentAddress': _walletAddress,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to register agent');
      }
    } catch (e) {
      debugPrint('Error registering agent: $e');
      rethrow;
    }
  }

  /// Add review for agent
  Future<Map<String, dynamic>> addReview({
    required String agentAddress,
    required int rating,
    required String propertyId,
    String? reviewText,
  }) async {
    if (!_isConnected || _walletAddress == null) {
      throw Exception('Wallet not connected');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agents/$agentAddress/review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reviewerAddress': _walletAddress,
          'rating': rating,
          'propertyId': propertyId,
          'reviewText': reviewText ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add review');
      }
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }

  /// Get agent reputation
  Future<Map<String, dynamic>> getAgentReputation(String agentAddress) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agents/$agentAddress/reputation'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get agent reputation');
      }
    } catch (e) {
      debugPrint('Error getting agent reputation: $e');
      rethrow;
    }
  }

  /// Report fraud
  Future<Map<String, dynamic>> reportFraud({
    required String agentAddress,
    required String propertyId,
    required String evidence,
  }) async {
    if (!_isConnected || _walletAddress == null) {
      throw Exception('Wallet not connected');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agents/$agentAddress/report-fraud'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'propertyId': propertyId,
          'evidence': evidence,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to report fraud');
      }
    } catch (e) {
      debugPrint('Error reporting fraud: $e');
      rethrow;
    }
  }

  // ============ Utility Functions ============

  /// Format Starknet address for display
  String formatAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  /// Validate Starknet address
  bool isValidAddress(String address) {
    return address.startsWith('0x') && address.length >= 60 && address.length <= 66;
  }
}
