import 'package:flutter/foundation.dart';
import '../services/starknet_service.dart';

class StarknetProvider with ChangeNotifier {
  final StarknetService _starknetService = StarknetService();

  bool _isInitialized = false;
  bool _isConnecting = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  bool get isConnected => _starknetService.isConnected;
  bool get isConnecting => _isConnecting;
  String? get walletAddress => _starknetService.walletAddress;
  String? get error => _error;

  StarknetProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _starknetService.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize Starknet service';
      debugPrint('Error initializing Starknet: $e');
      notifyListeners();
    }
  }

  /// Connect wallet
  Future<bool> connectWallet(String walletAddress) async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _starknetService.connectWallet(walletAddress);
      _isConnecting = false;
      
      if (!success) {
        _error = 'Failed to connect wallet';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _isConnecting = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Disconnect wallet
  Future<void> disconnectWallet() async {
    await _starknetService.disconnectWallet();
    _error = null;
    notifyListeners();
  }

  /// Mint property NFT
  Future<Map<String, dynamic>?> mintProperty(String propertyId) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _starknetService.mintProperty(propertyId);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get property blockchain details
  Future<Map<String, dynamic>?> getPropertyBlockchainDetails(String propertyId) async {
    try {
      return await _starknetService.getPropertyBlockchainDetails(propertyId);
    } catch (e) {
      debugPrint('Error getting blockchain details: $e');
      return null;
    }
  }

  /// Create escrow
  Future<Map<String, dynamic>?> createEscrow({
    required String propertyId,
    required double amount,
    required String escrowType,
    String? releaseConditions,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _starknetService.createEscrow(
        propertyId: propertyId,
        amount: amount,
        escrowType: escrowType,
        releaseConditions: releaseConditions,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get escrow status
  Future<Map<String, dynamic>?> getEscrowStatus(String escrowId) async {
    try {
      return await _starknetService.getEscrowStatus(escrowId);
    } catch (e) {
      debugPrint('Error getting escrow status: $e');
      return null;
    }
  }

  /// Register as agent
  Future<Map<String, dynamic>?> registerAgent(Map<String, dynamic> metadata) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _starknetService.registerAgent(metadata);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Add review
  Future<Map<String, dynamic>?> addReview({
    required String agentAddress,
    required int rating,
    required String propertyId,
    String? reviewText,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _starknetService.addReview(
        agentAddress: agentAddress,
        rating: rating,
        propertyId: propertyId,
        reviewText: reviewText,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get agent reputation
  Future<Map<String, dynamic>?> getAgentReputation(String agentAddress) async {
    try {
      return await _starknetService.getAgentReputation(agentAddress);
    } catch (e) {
      debugPrint('Error getting agent reputation: $e');
      return null;
    }
  }

  /// Report fraud
  Future<Map<String, dynamic>?> reportFraud({
    required String agentAddress,
    required String propertyId,
    required String evidence,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _starknetService.reportFraud(
        agentAddress: agentAddress,
        propertyId: propertyId,
        evidence: evidence,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Format address for display
  String formatAddress(String address) {
    return _starknetService.formatAddress(address);
  }

  /// Validate address
  bool isValidAddress(String address) {
    return _starknetService.isValidAddress(address);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
