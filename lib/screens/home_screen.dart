import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/settings_provider.dart';
import '../providers/compare_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/property_card.dart';
import 'explore_screen.dart';
import 'compare_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'all_properties_screen.dart';
import 'loading_screen.dart';
import 'appointments_screen.dart';
import 'search_screen.dart';

/// Maps display category name → PropertyType enum name
const Map<String, String> _categoryTypeMap = {
  'Apartment': 'apartment',
  'House': 'house',
  'Villa': 'villa',
  'Land': 'land',
  'Commercial': 'commercial',
  'Studio': 'studio',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Property> _featuredProperties = [];
  List<Property> _recentProperties = [];
  List<Property> _allProperties = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedCategory = 'All';
  String? _selectedQuickFilter;

  final List<String> _categories = [
    'All',
    'Apartment',
    'House',
    'Villa',
    'Land',
    'Commercial',
    'Studio',
  ];

  final List<String> _quickFilters = const [
    '📍 Kampala',
    '🏠 House',
    '🏢 Apartment',
    '💰 Under 500k',
    '🛏 2 Bedrooms',
  ];

  List<Property> _filterByCategory(List<Property> properties) {
    if (_selectedCategory == 'All') return _filterByQuickFilter(properties);
    final targetType = _categoryTypeMap[_selectedCategory];
    if (targetType == null) return properties;
    final categoryFiltered = properties
        .where((p) =>
            p.type.toString().split('.').last.toLowerCase() == targetType)
        .toList();
    return _filterByQuickFilter(categoryFiltered);
  }

  List<Property> _filterByQuickFilter(List<Property> properties) {
    switch (_selectedQuickFilter) {
      case '📍 Kampala':
        return properties
            .where((p) => p.location.toLowerCase().contains('kampala'))
            .toList();
      case '🏠 House':
        return properties
            .where((p) => p.type.toString().split('.').last.toLowerCase() == 'house')
            .toList();
      case '🏢 Apartment':
        return properties
            .where((p) => p.type.toString().split('.').last.toLowerCase() == 'apartment')
            .toList();
      case '💰 Under 500k':
        return properties.where((p) => p.price <= 500000).toList();
      case '🛏 2 Bedrooms':
        return properties.where((p) => (p.size.bedrooms ?? 0) == 2).toList();
      default:
        return properties;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProperties();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties({bool forceRefresh = false}) async {
    try {
      final properties =
          await ApiService.getAllProperties(forceRefresh: forceRefresh);
      final recentProperties = List<Property>.from(properties)
        ..sort((a, b) => b.datePosted.compareTo(a.datePosted));
      final featuredProperties =
          properties.where((property) => property.isFeatured).toList();

      setState(() {
        _featuredProperties = featuredProperties;
        _recentProperties = recentProperties;
        _allProperties = properties;
        _isLoading = false;
      });
      _animationController.forward();

      // Trigger simulated push alerts if settings are enabled
      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted) return;
        final settings = context.read<SettingsProvider>();
        if (settings.propertyUpdatesEnabled) {
          NotificationService.showNotification(
            id: 991,
            title: 'New Property Alert! 🏠',
            body: 'A beautiful 5-bedroom townhouse is now available in Munyonyo.',
          );
        }
        if (settings.priceChangesEnabled) {
          Future.delayed(const Duration(seconds: 5), () {
            if (!mounted) return;
            if (settings.priceChangesEnabled) {
              NotificationService.showNotification(
                id: 992,
                title: 'Price Drop Alert! 📉',
                body: 'Price drop: 2-bedroom executive apartment in Muyenga is now UGX 2,200,000/mo (was UGX 2,500,000).',
              );
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _featuredProperties = [];
        _recentProperties = [];
        _allProperties = [];
        _isLoading = false;
      });
      _animationController.forward();
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? const LoadingScreen() : _buildMainContent(),
      floatingActionButton: _buildCompareFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const ExploreScreen(),
          const FavoritesScreen(),
          const AppointmentsScreen(showBackButton: false),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () => _loadProperties(forceRefresh: true),
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildDynamicAppBar(),
          _buildWelcomeHero(),
          _buildPremiumSearchBar(),
          _buildQuickFilterChips(),
          _buildCategoryFilter(),
          _buildFeaturedSection(),
          _buildRecommendedSection(),
          _buildPopularLocationsSection(),
          _buildTrendingSection(),
          _buildLatestListingsSection(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildDynamicAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              child: SvgPicture.asset(
                isDark
                    ? 'assets/images/dnblogdark-removebg-preview.svg'
                    : 'assets/images/dnblogolight-removebg-preview.svg',
                width: 48,
                height: 48,
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF178F5B), Color(0xFF1A3C6E)],
                      ).createShader(bounds),
                      child: const Text(
                        'dnb ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: const Text(
                        'Homes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFA17324),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildWelcomeHero() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7)
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Your Dream Home',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_allProperties.length} premium properties available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search properties, locations or agents...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.62),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 62,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          itemCount: _quickFilters.length,
          itemBuilder: (context, index) {
            final filter = _quickFilters[index];
            final isSelected = _selectedQuickFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedQuickFilter = isSelected ? null : filter;
                    if (isSelected && (filter == '🏠 House' || filter == '🏢 Apartment')) {
                      _selectedCategory = 'All';
                    } else {
                      if (filter == '🏠 House') _selectedCategory = 'House';
                      if (filter == '🏢 Apartment') _selectedCategory = 'Apartment';
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withOpacity(isDark ? 0.22 : 0.12)
                        : isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? primary.withOpacity(0.35)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Text(
                  'Browse by Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [primary, primary.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.65),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final filtered = _filterByCategory(_featuredProperties);
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Featured Properties',
            'Premium handpicked listings',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'Featured Properties',
                  initialProperties: filtered,
                  showFeaturedOnly: true,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: filtered.isEmpty
                ? _buildEmptyState('No featured properties', Icons.star_outline)
                : _buildHorizontalPropertyList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final filtered = _filterByCategory(_allProperties);
    final recommended = filtered.where((Property property) {
      final type = property.type.toString().split('.').last.toLowerCase();
      return property.isFeatured || type == 'house' || type == 'apartment';
    }).take(8).toList();
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Recommended For You',
            'Smart picks based on popular searches',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'Recommended For You',
                  initialProperties: recommended,
                  showFeaturedOnly: false,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: recommended.isEmpty
                ? _buildEmptyState('No recommendations yet', Icons.auto_awesome_outlined)
                : _buildHorizontalPropertyList(recommended),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularLocationsSection() {
    final Map<String, int> locationCounts = <String, int>{};
    for (final Property property in _allProperties) {
      final String location = property.location.split(',').first.trim();
      if (location.isEmpty) continue;
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }
    final locations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Popular Locations',
            'Areas people are exploring now',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          SizedBox(
            height: 112,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: locations.take(8).length,
              itemBuilder: (context, index) {
                final entry = locations[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  child: Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF178F5B), size: 22),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${entry.value} listings',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    final trending = _filterByCategory(_allProperties).toList()
      ..sort((a, b) => (b.views + b.favorites).compareTo(a.views + a.favorites));
    final displayed = trending.take(8).toList();
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Trending This Week',
            'Listings getting the most attention',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'Trending This Week',
                  initialProperties: displayed,
                  showFeaturedOnly: false,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: displayed.isEmpty
                ? _buildEmptyState('No trending listings yet', Icons.trending_up_rounded)
                : _buildHorizontalPropertyList(displayed),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestListingsSection() {
    final filtered = _filterByCategory(_recentProperties);
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Latest Listings',
            'Fresh properties on the market',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'Latest Listings',
                  initialProperties: filtered,
                  showFeaturedOnly: false,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: filtered.isEmpty
                ? _buildEmptyState('No recent properties', Icons.access_time)
                : _buildHorizontalPropertyList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'View All',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPropertyList(List<Property> properties) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = screenWidth > 600 ? 320.0 : screenWidth * 0.75;

        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 16),
          child: PropertyCard(
            propertyId: properties[index].id,
            initialProperty: properties[index],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildFloatingActionButton() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
  //           blurRadius: 12,
  //           offset: const Offset(0, 6),
  //         ),
  //       ],
  //     ),
  //     child: FloatingActionButton.extended(
  //       onPressed: () => Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => const AIChatScreen()),
  //       ),
  //       icon: const Icon(Icons.forum_rounded),
  //       label: const Text(
  //         'AI Chat',
  //         style: TextStyle(fontWeight: FontWeight.w600),
  //       ),
  //       backgroundColor: Theme.of(context).colorScheme.primary,
  //       foregroundColor: Theme.of(context).colorScheme.onPrimary,
  //       elevation: 0,
  //     ),
  //   );
  // }

  /// Per-tab accent colors — ordered by nav index
  static const _tabColors = [
    Color(0xFF178F5B), // 0 Home     — emerald green (brand)
    Color(0xFF178F5B), // 1 Discover — emerald green
    Color(0xFFA17324), // 2 Favorites — gold
    Color(0xFF1A3C6E), // 3 Bookings  — navy
  ];

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A0F1D)
            : Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, null, 'Home', isLogo: true),
              _buildNavItem(1, Icons.explore_rounded, 'Discover'),
              _buildNavItem(2, Icons.favorite_rounded, 'Favorites'),
              _buildNavItem(3, Icons.calendar_month_rounded, 'Bookings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData? icon,
    String label, {
    bool isLogo = false,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabColor = _tabColors[index];
    final inactiveColor = isDark
        ? Colors.white
        : Colors.black;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? tabColor.withOpacity(isDark ? 0.18 : 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: tabColor.withOpacity(0.22), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon / Logo ──────────────────────────────────
              if (isLogo)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: isSelected ? 42 : 36,
                  height: isSelected ? 42 : 36,
                  child: SvgPicture.asset(
                    isDark
                        ? 'assets/images/dnblogdark-removebg-preview.svg'
                        : 'assets/images/dnblogolight-removebg-preview.svg',
                    fit: BoxFit.contain,
                  ),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tabColor.withOpacity(isDark ? 0.25 : 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? tabColor : inactiveColor,
                    size: 24,
                  ),
                ),

              const SizedBox(height: 5),

              // ── Label ────────────────────────────────────────
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? tabColor : inactiveColor,
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildCompareFloatingButton() {
    final count = context.watch<CompareProvider>().compareList.length;
    if (count < 2) return null;
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompareScreen(
            onGoHome: () => Navigator.pop(context),
          ),
        ),
      ),
      icon: const Icon(Icons.balance_rounded),
      label: Text('Compare ($count)'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }
}
