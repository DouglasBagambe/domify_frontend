import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/starknet_provider.dart';

class WalletConnectScreen extends StatefulWidget {
  const WalletConnectScreen({super.key});

  @override
  State<WalletConnectScreen> createState() => _WalletConnectScreenState();
}

class _WalletConnectScreenState extends State<WalletConnectScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _connectWallet() async {
    final address = _addressController.text.trim();
    
    if (address.isEmpty) {
      _showError('Please enter a wallet address');
      return;
    }

    final starknetProvider = Provider.of<StarknetProvider>(context, listen: false);
    
    if (!starknetProvider.isValidAddress(address)) {
      _showError('Invalid Starknet address format');
      return;
    }

    setState(() => _isLoading = true);

    final success = await starknetProvider.connectWallet(address);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      _showSuccess('Wallet connected successfully!');
    } else if (mounted) {
      _showError(starknetProvider.error ?? 'Failed to connect wallet');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Starknet Wallet'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Starknet Logo/Icon
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Connect Your Wallet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Enter your Starknet wallet address to unlock blockchain features like property verification, secure escrow, and reputation tracking.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Wallet Address Input
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Starknet Wallet Address',
                hintText: '0x...',
                prefixIcon: const Icon(Icons.wallet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Use Argent X or Braavos wallet address',
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _connectWallet(),
            ),
            
            const SizedBox(height: 32),
            
            // Connect Button
            ElevatedButton(
              onPressed: _isLoading ? null : _connectWallet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Connect Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Features List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blockchain Features',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.verified,
                      'Property Verification',
                      'Mint and verify properties as NFTs',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.lock,
                      'Secure Escrow',
                      'Protected payments and deposits',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.star,
                      'Reputation System',
                      'Transparent agent ratings',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.history,
                      'Ownership History',
                      'Complete property transaction records',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help Text
            TextButton(
              onPressed: () {
                // Show help dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('How to Get a Wallet'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('1. Download Argent X or Braavos wallet extension'),
                          SizedBox(height: 8),
                          Text('2. Create a new wallet or import existing'),
                          SizedBox(height: 8),
                          Text('3. Copy your wallet address'),
                          SizedBox(height: 8),
                          Text('4. Paste it in the field above'),
                          SizedBox(height: 16),
                          Text(
                            'Note: Make sure you\'re on Starknet Sepolia testnet for testing.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Don\'t have a wallet? Learn how to get one'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
