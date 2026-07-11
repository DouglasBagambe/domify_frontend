import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/compare_provider.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';

class CompareScreen extends StatefulWidget {
  final VoidCallback? onGoHome;

  const CompareScreen({super.key, this.onGoHome});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen>
    with TickerProviderStateMixin {
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _selectedTab = 0;

  // Track last known compare list to detect changes
  List<String> _lastCompareIds = [];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // React to compare list changes (e.g. user added from home tab)
    final compareIds =
        List<String>.from(Provider.of<CompareProvider>(context).compareList);
    if (_listsDiffer(compareIds, _lastCompareIds)) {
      _lastCompareIds = compareIds;
      _loadProperties(compareIds);
    }
  }

  bool _listsDiffer(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties(List<String> ids) async {
    if (ids.isEmpty) {
      setState(() {
        _properties = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Property> loaded = [];
      for (final id in ids) {
        final p = await ApiService.getPropertyById(id);
        loaded.add(p);
      }
      setState(() {
        _properties = loaded;
        _isLoading = false;
      });
      if (loaded.length == 2) {
        _slideController.forward(from: 0);
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load one or more properties. Try again.';
        _isLoading = false;
        _properties = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildBody(),
      floatingActionButton:
          _properties.length == 2 ? _buildFloatingActions() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_properties.length != 2) return _buildEmptyState();
    return _buildCompareContent();
  }

  // ─── Loading ──────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 24),
          Text('Loading Properties...',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 24),
            Text('Something went wrong',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<CompareProvider>(context, listen: false)
                    .clearCompare();
                setState(() {
                  _error = null;
                  _properties = [];
                  _lastCompareIds = [];
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear & Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final count = _lastCompareIds.length;
    final needMore = 2 - count;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.balance,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 32),
            Text(
              count == 0 ? 'Compare Properties' : 'Almost There!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Show progress pills
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _selectionPill(1, count >= 1),
                const SizedBox(width: 8),
                _selectionPill(2, count >= 2),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              count == 0
                  ? 'Tap the ⚖️ icon on any property card to add it to your comparison.'
                  : 'Select $needMore more propert${needMore == 1 ? "y" : "ies"} to unlock the comparison.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            if (count > 0)
              OutlinedButton.icon(
                onPressed: () {
                  Provider.of<CompareProvider>(context, listen: false)
                      .clearCompare();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Selection'),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Go to Home tab via callback, or pop if navigated here directly
                if (widget.onGoHome != null) {
                  widget.onGoHome!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Properties'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionPill(int number, bool filled) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: filled
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text('$number',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
      ),
    );
  }

  // ─── Compare Content ──────────────────────────────────────────────────────
  Widget _buildCompareContent() {
    return Column(
      children: [
        _buildCustomAppBar(),
        _buildTabBar(),
        Expanded(
          child: _selectedTab == 0 ? _buildOverviewTab() : _buildDetailedTab(),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Text(
              'Property Comparison',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.clear_all,
                  color: Theme.of(context).colorScheme.error),
              onPressed: () {
                Provider.of<CompareProvider>(context, listen: false)
                    .clearCompare();
              },
              tooltip: 'Clear comparison',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tab(0, 'Overview'),
          _tab(1, 'Details'),
        ],
      ),
    );
  }

  Widget _tab(int index, String label) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildPropertyCards(),
              const SizedBox(height: 24),
              _buildQuickComparison(),
              const SizedBox(height: 24),
              _buildWinnerCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildPropertyCards(),
            const SizedBox(height: 24),
            _buildDetailedComparison(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCards() {
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PropertyCard(propertyId: _properties[0].id),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              'VS',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PropertyCard(propertyId: _properties[1].id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Comparison',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildComparisonRow('Price',
              'UGX ${_formatPrice(_properties[0].price)}',
              'UGX ${_formatPrice(_properties[1].price)}',
              _properties[0].price < _properties[1].price ? 0 : 1),
          _buildComparisonRow('Area',
              '${_properties[0].size.totalArea.toStringAsFixed(0)} sq ft',
              '${_properties[1].size.totalArea.toStringAsFixed(0)} sq ft',
              _properties[0].size.totalArea > _properties[1].size.totalArea
                  ? 0
                  : 1),
          _buildComparisonRow('Bedrooms',
              '${_properties[0].size.bedrooms ?? 0}',
              '${_properties[1].size.bedrooms ?? 0}',
              (_properties[0].size.bedrooms ?? 0) >
                      (_properties[1].size.bedrooms ?? 0)
                  ? 0
                  : 1),
          _buildComparisonRow('Bathrooms',
              '${_properties[0].size.bathrooms ?? 0}',
              '${_properties[1].size.bathrooms ?? 0}',
              (_properties[0].size.bathrooms ?? 0) >
                      (_properties[1].size.bathrooms ?? 0)
                  ? 0
                  : 1),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
      String label, String v1, String v2, int winner) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: _comparisonCell(v1, winner == 0)),
          const SizedBox(width: 8),
          Expanded(child: _comparisonCell(v2, winner == 1)),
        ],
      ),
    );
  }

  Widget _comparisonCell(String value, bool isWinner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          if (isWinner) ...[
            Icon(Icons.star,
                size: 12, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCard() {
    final p0ppsf = _properties[0].price / _properties[0].size.totalArea;
    final p1ppsf = _properties[1].price / _properties[1].size.totalArea;
    final winnerIndex = p0ppsf < p1ppsf ? 0 : 1;
    final winner = _properties[winnerIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events,
              color: Theme.of(context).colorScheme.tertiary, size: 40),
          const SizedBox(height: 8),
          Text('Best Value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).colorScheme.onTertiaryContainer)),
          const SizedBox(height: 4),
          Text(winner.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onTertiaryContainer)),
          const SizedBox(height: 4),
          Text(
            '${(winnerIndex == 0 ? p0ppsf : p1ppsf).toStringAsFixed(0)} UGX/sq ft',
            style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedComparison() {
    return Column(
      children: [
        _detailSection('Price',
            ['UGX ${_formatPrice(_properties[0].price)}', 'UGX ${_formatPrice(_properties[1].price)}'],
            Icons.attach_money),
        _detailSection('Location',
            [_properties[0].location, _properties[1].location],
            Icons.location_on),
        _detailSection('Type', [
          _properties[0].type.toString().split('.').last,
          _properties[1].type.toString().split('.').last
        ], Icons.home),
        _detailSection('Purpose', [
          _properties[0].purpose.toString().split('.').last,
          _properties[1].purpose.toString().split('.').last
        ], Icons.business),
        _detailSection('Size', [
          '${_properties[0].size.totalArea.toStringAsFixed(0)} sq ft',
          '${_properties[1].size.totalArea.toStringAsFixed(0)} sq ft'
        ], Icons.square_foot),
        _detailSection('Bedrooms', [
          '${_properties[0].size.bedrooms ?? 0}',
          '${_properties[1].size.bedrooms ?? 0}'
        ], Icons.bed),
        _detailSection('Bathrooms', [
          '${_properties[0].size.bathrooms ?? 0}',
          '${_properties[1].size.bathrooms ?? 0}'
        ], Icons.bathtub),
        _detailSection('Amenities', [
          _properties[0].amenities.join(', '),
          _properties[1].amenities.join(', ')
        ], Icons.star),
      ],
    );
  }

  Widget _detailSection(String title, List<String> values, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _detailCell(values[0])),
              const SizedBox(width: 12),
              Expanded(child: _detailCell(values[1])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailCell(String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'compare_share',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share comparison link copied!')),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: const Icon(Icons.share),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'compare_clear',
          onPressed: () {
            Provider.of<CompareProvider>(context, listen: false).clearCompare();
          },
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.error,
          child: const Icon(Icons.compare_arrows),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) return '${(price / 1000000000).toStringAsFixed(1)}B';
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}