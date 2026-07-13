import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/compare_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../screens/property_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ULTRA-PREMIUM COMPARE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
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
  int _selectedTab = 0;
  List<String> _lastCompareIds = [];

  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
        parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryController, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ids = List<String>.from(
        Provider.of<CompareProvider>(context).compareList);
    if (_listsDiffer(ids, _lastCompareIds)) {
      _lastCompareIds = ids;
      _loadProperties(ids);
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
    _entryController.dispose();
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
        loaded.add(await ApiService.getPropertyById(id));
      }
      setState(() {
        _properties = loaded;
        _isLoading = false;
      });
      if (loaded.length == 2) _entryController.forward(from: 0);
    } catch (_) {
      setState(() {
        _error = 'Could not load properties.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildAppBar(cs),
          Expanded(
            child: _isLoading
                ? _buildLoading(cs)
                : _error != null
                    ? _buildError(cs)
                    : _properties.length != 2
                        ? _buildEmptyState(cs)
                        : _buildComparePage(cs),
          ),
        ],
      ),
    );
  }

  // ─── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading(ColorScheme cs) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text('Loading…',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      );

  // ─── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Provider.of<CompareProvider>(context, listen: false)
                  .clearCompare();
              setState(() {
                _error = null;
                _lastCompareIds = [];
              });
            },
            child: const Text('Clear & Retry'),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    final count = _lastCompareIds.length;
    final need = 2 - count;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant icon pair
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _propertySlot(cs, count >= 1, '1'),
              const SizedBox(width: 16),
              Icon(Icons.compare_arrows_rounded,
                  color: cs.primary.withOpacity(0.5), size: 28),
              const SizedBox(width: 16),
              _propertySlot(cs, count >= 2, '2'),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            count == 0 ? 'Compare Properties' : 'One More to Go',
            style: tt.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            count == 0
                ? 'Tap the ⚖ icon on any property card to add it to your compare list.'
                : 'Add $need more propert${need == 1 ? 'y' : 'ies'} to start comparing.',
            style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          if (count > 0) ...[
            OutlinedButton.icon(
              onPressed: () => Provider.of<CompareProvider>(context,
                      listen: false)
                  .clearCompare(),
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Clear Selection'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () {
              if (widget.onGoHome != null) {
                widget.onGoHome!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Browse Properties'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertySlot(ColorScheme cs, bool filled, String num) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: filled ? cs.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? cs.primary : cs.outline.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: filled
            ? Icon(Icons.check_rounded, color: cs.onPrimary, size: 22)
            : Text(num,
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
      ),
    );
  }

  // ─── Compare Page ──────────────────────────────────────────────────────────
  Widget _buildComparePage(ColorScheme cs) {
    return Column(
      children: [
        _buildTabBar(cs),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _selectedTab == 0
                  ? _buildOverview(cs)
                  : _buildDetails(cs),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(ColorScheme cs) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF101828);
    final count = _lastCompareIds.length;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const <Color>[Color(0xFF101625), Color(0xFF111E18)]
                  : const <Color>[Colors.white, Color(0xFFEFFDF5)],
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E2D3B)
                  : const Color(0xFFDCFCE7),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(
                  isDark ? 0.22 : 0.06,
                ),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Material(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (widget.onGoHome != null) {
                      widget.onGoHome!();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFF178F5B),
                      Color(0xFF1A3C6E),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compare',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0
                          ? 'No properties'
                          : count == 1
                              ? '1 property added'
                              : 'Comparing 2 properties',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.58),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _tab(0, 'Overview', cs),
          const SizedBox(width: 8),
          _tab(1, 'Details', cs),
        ],
      ),
    );
  }

  Widget _tab(int index, String label, ColorScheme cs) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? cs.primary
                : cs.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ─── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverview(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildPropertyHeaderRow(cs),
          const SizedBox(height: 24),
          _buildMetricGrid(cs),
          const SizedBox(height: 24),
          _buildValueBadge(cs),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPropertyHeaderRow(ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: _miniPropertyCard(_properties[0], cs, tt, 0)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('vs',
              style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
        Expanded(child: _miniPropertyCard(_properties[1], cs, tt, 1)),
      ],
    );
  }

  Widget _miniPropertyCard(
      Property p, ColorScheme cs, TextTheme tt, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(propertyId: p.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: p.images.isNotEmpty
                    ? Image.network(p.images[0],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.primaryContainer,
                          child: Icon(Icons.home,
                              color: cs.primary, size: 24),
                        ))
                    : Container(
                        color: cs.primaryContainer,
                        child: Icon(Icons.home,
                            color: cs.primary, size: 24)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.title,
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _fmtPrice(p.price),
              style: tt.bodyMedium?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    final p0 = _properties[0];
    final p1 = _properties[1];

    final metrics = [
      _CompareMetric(
        label: 'Price',
        v0: _fmtPrice(p0.price),
        v1: _fmtPrice(p1.price),
        winner: p0.price < p1.price ? 0 : 1,
        icon: Icons.attach_money_rounded,
      ),
      _CompareMetric(
        label: 'Area',
        v0: '${p0.size.totalArea.toStringAsFixed(0)} sq ft',
        v1: '${p1.size.totalArea.toStringAsFixed(0)} sq ft',
        winner: p0.size.totalArea > p1.size.totalArea ? 0 : 1,
        icon: Icons.square_foot_rounded,
      ),
      _CompareMetric(
        label: 'Bedrooms',
        v0: '${p0.size.bedrooms ?? 0}',
        v1: '${p1.size.bedrooms ?? 0}',
        winner: (p0.size.bedrooms ?? 0) >= (p1.size.bedrooms ?? 0) ? 0 : 1,
        icon: Icons.bed_rounded,
      ),
      _CompareMetric(
        label: 'Bathrooms',
        v0: '${p0.size.bathrooms ?? 0}',
        v1: '${p1.size.bathrooms ?? 0}',
        winner: (p0.size.bathrooms ?? 0) >= (p1.size.bathrooms ?? 0) ? 0 : 1,
        icon: Icons.bathtub_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                    flex: 2, child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: Text(
                    _properties[0].title,
                    style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _properties[1].title,
                    style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...metrics.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            return Column(
              children: [
                _metricRow(m, cs, tt),
                if (i < metrics.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }).toList(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _metricRow(_CompareMetric m, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(m.icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(m.label,
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _metricCell(m.v0, m.winner == 0, cs, tt, align: TextAlign.left),
          ),
          Expanded(
            flex: 3,
            child: _metricCell(m.v1, m.winner == 1, cs, tt, align: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _metricCell(String value, bool isWinner, ColorScheme cs, TextTheme tt,
      {required TextAlign align}) {
    return Row(
      mainAxisAlignment: align == TextAlign.right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (isWinner && align == TextAlign.left) ...[
          Icon(Icons.arrow_upward_rounded,
              size: 11, color: Colors.green.shade600),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: tt.bodySmall?.copyWith(
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
            color: isWinner ? cs.onSurface : cs.onSurfaceVariant,
            fontSize: 13,
          ),
          textAlign: align,
        ),
        if (isWinner && align == TextAlign.right) ...[
          const SizedBox(width: 4),
          Icon(Icons.arrow_upward_rounded,
              size: 11, color: Colors.green.shade600),
        ],
      ],
    );
  }

  Widget _buildValueBadge(ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    final p0 = _properties[0];
    final p1 = _properties[1];
    final ppsf0 = p0.size.totalArea > 0
        ? p0.price / p0.size.totalArea
        : double.infinity;
    final ppsf1 = p1.size.totalArea > 0
        ? p1.price / p1.size.totalArea
        : double.infinity;
    final winner = ppsf0 <= ppsf1 ? p0 : p1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_rounded,
                color: Colors.amber.shade700, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Value',
                    style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(winner.title,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${_fmtPrice(ppsf0 <= ppsf1 ? ppsf0 : ppsf1)} / sq ft',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Details Tab ───────────────────────────────────────────────────────────
  Widget _buildDetails(ColorScheme cs) {
    final p0 = _properties[0];
    final p1 = _properties[1];
    final tt = Theme.of(context).textTheme;

    final sections = [
      _DetailSection('Location', [p0.location, p1.location],
          Icons.location_on_outlined),
      _DetailSection(
          'Type',
          [
            p0.type.toString().split('.').last,
            p1.type.toString().split('.').last
          ],
          Icons.home_outlined),
      _DetailSection(
          'Purpose',
          [
            p0.purpose.toString().split('.').last,
            p1.purpose.toString().split('.').last
          ],
          Icons.sell_outlined),
      _DetailSection(
          'Size',
          [
            '${p0.size.totalArea.toStringAsFixed(0)} sq ft',
            '${p1.size.totalArea.toStringAsFixed(0)} sq ft'
          ],
          Icons.square_foot_rounded),
      _DetailSection(
          'Bedrooms',
          ['${p0.size.bedrooms ?? 0}', '${p1.size.bedrooms ?? 0}'],
          Icons.bed_outlined),
      _DetailSection(
          'Bathrooms',
          ['${p0.size.bathrooms ?? 0}', '${p1.size.bathrooms ?? 0}'],
          Icons.bathtub_outlined),
      _DetailSection(
          'Price',
          [_fmtPrice(p0.price), _fmtPrice(p1.price)],
          Icons.attach_money_rounded),
      _DetailSection(
          'Amenities',
          [p0.amenities.join(', '), p1.amenities.join(', ')],
          Icons.stars_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Column headers
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                flex: 3,
                child: Text(p0.title,
                    style: tt.labelSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(p1.title,
                    style: tt.labelSmall?.copyWith(
                        color: cs.secondary, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: cs.outline.withOpacity(0.12)),
            ),
            child: Column(
              children: sections.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Column(
                  children: [
                    _detailSectionRow(s, cs, tt),
                    if (i < sections.length - 1)
                      const Divider(
                          height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _detailSectionRow(
      _DetailSection s, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s.icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(s.label,
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(s.values[0],
                style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(s.values[1],
                style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: cs.secondary),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double price) {
    return context.read<SettingsProvider>().formatPrice(price, compact: true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models for compare rows
// ─────────────────────────────────────────────────────────────────────────────
class _CompareMetric {
  final String label;
  final String v0;
  final String v1;
  final int winner;
  final IconData icon;
  const _CompareMetric({
    required this.label,
    required this.v0,
    required this.v1,
    required this.winner,
    required this.icon,
  });
}

class _DetailSection {
  final String label;
  final List<String> values;
  final IconData icon;
  const _DetailSection(this.label, this.values, this.icon);
}
