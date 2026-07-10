import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';
import 'filter_screen.dart';
import 'explore_screen.dart';
import 'compare_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'all_properties_screen.dart';
import 'loading_screen.dart';
import 'ai_chat_screen.dart';

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

  final List<String> _categories = [
    'All',
    'Apartment',
    'House',
    'Villa',
    'Land',
    'Commercial',
    'Studio',
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.search_rounded,
      'label': 'Filter',
      'color': Color(0xFF178F5B)
    },
    {
      'icon': Icons.fiber_new_rounded,
      'label': 'New Listings',
      'color': Color(0xFF1A3C6E)
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'label': 'Explore',
      'color': Color(0xFFA17324)
    },
    {
      'icon': Icons.bookmarks_outlined,
      'label': 'Saved',
      'color': Color(0xFF178F5B)
    },
  ];

  List<Property> _filterByCategory(List<Property> properties) {
    if (_selectedCategory == 'All') return properties;
    final targetType = _categoryTypeMap[_selectedCategory];
    if (targetType == null) return properties;
    return properties
        .where((p) =>
            p.type.toString().split('.').last.toLowerCase() == targetType)
        .toList();
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

  Future<void> _loadProperties() async {
    try {
      final results = await Future.wait([
        ApiService.getFeaturedProperties(),
        ApiService.getRecentProperties(),
        ApiService.getAllProperties(),
      ]);

      setState(() {
        _featuredProperties = results[0];
        _recentProperties = results[1];
        _allProperties = results[2];
        _isLoading = false;
      });
      _animationController.forward();
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
      floatingActionButton: _currentIndex == 0 ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          const FavoritesScreen(),
          const CompareScreen(),
          const ExploreScreen(),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadProperties,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildDynamicAppBar(),
          _buildWelcomeHero(),
          _buildQuickActions(),
          _buildCategoryFilter(),
          _buildFeaturedSection(),
          _buildRecentSection(),
          _buildAllPropertiesSection(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildDynamicAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            isDark
                ? 'assets/images/dnblogdark-removebg-preview.svg'
                : 'assets/images/dnblogolight-removebg-preview.svg',
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text(
            'Homes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFA17324),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
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

  void _handleQuickAction(String label) {
    switch (label) {
      case 'Filter':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FilterScreen()),
        );
        break;
      case 'New Listings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllPropertiesScreen(
              title: 'New Listings',
              initialProperties: _recentProperties,
              showFeaturedOnly: false,
            ),
          ),
        );
        break;
      case 'Explore':
        setState(() => _currentIndex = 2);
        break;
      case 'Saved':
        setState(() => _currentIndex = 1);
        break;
    }
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: _quickActions.map((action) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleQuickAction(action['label'] as String),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: action['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                action['icon'],
                                color: action['color'],
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              action['label'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            
            return Container(
              margin: const EdgeInsets.only(right: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
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

  Widget _buildRecentSection() {
    final filtered = _filterByCategory(_recentProperties);
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Recent Listings',
            'Latest properties on market',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'Recent Listings',
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

  Widget _buildAllPropertiesSection() {
    final filtered = _filterByCategory(_allProperties);
    final displayed = filtered.take(6).toList();
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'All Properties',
            'Browse our complete collection',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllPropertiesScreen(
                  title: 'All Properties',
                  initialProperties: filtered,
                  showFeaturedOnly: false,
                ),
              ),
            ),
          ),
          displayed.isEmpty
              ? _buildEmptyState(
                  'No properties in this category', Icons.home_outlined)
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    return PropertyCard(propertyId: displayed[index].id);
                  },
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
          child: PropertyCard(propertyId: properties[index].id),
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

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIChatScreen()),
        ),
        icon: const Icon(Icons.forum_rounded),
        label: const Text(
          'AI Chat',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
    );
  }

  /// Per-tab accent colors — ordered by nav index
  static const _tabColors = [
    Color(0xFF178F5B), // 0 Home     — emerald green (brand)
    Color(0xFFA17324), // 1 Favorites — gold
    Color(0xFF3B82F6), // 2 Compare   — blue
    Color(0xFF178F5B), // 3 Explore   — emerald green
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
              _buildNavItem(1, Icons.favorite_rounded, 'Favorites'),
              _buildNavItem(2, Icons.balance_rounded, 'Compare'),
              _buildNavItem(3, Icons.auto_awesome_rounded, 'Explore'),
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
}