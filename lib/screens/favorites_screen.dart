import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  List<Property> _favoriteProperties = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, price_low, price_high, name
  bool _isGridView = true;
  
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _searchAnimationController;
  late AnimationController _staggerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;
  late Animation<double> _searchAnimation;
  late Animation<double> _staggerAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFavoriteProperties();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutBack),
    );
    _searchAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeOutCubic),
    );
    _staggerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerAnimationController, curve: Curves.easeOutQuart),
    );
    
    // Start animations with staggered timing
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _searchAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 100) {
        if (_fabAnimationController.status != AnimationStatus.reverse) {
          _fabAnimationController.reverse();
        }
      } else {
        if (_fabAnimationController.status != AnimationStatus.forward) {
          _fabAnimationController.forward();
        }
      }
    });
  }

  Future<void> _loadFavoriteProperties() async {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    if (favoritesProvider.favorites.isEmpty) {
      setState(() {
        _favoriteProperties = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Property> properties = [];
      for (String propertyId in favoritesProvider.favorites) {
        try {
          final property = await ApiService.getPropertyById(propertyId);
          if (property != null) {
            properties.add(property);
          }
        } catch (e) {
          // Skip properties that can't be loaded
          continue;
        }
      }
      
      setState(() {
        _favoriteProperties = properties;
        _isLoading = false;
      });
      
      // Trigger stagger animation for loaded properties
      _staggerAnimationController.reset();
      _staggerAnimationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Property> get _filteredAndSortedProperties {
    var filtered = _favoriteProperties.where((property) {
      if (_searchQuery.isEmpty) return true;
      return property.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             property.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             property.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'recent':
      default:
        // Keep original order or sort by any available field
        break;
    }

    return filtered;
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _searchAnimationController.dispose();
    _staggerAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAnimatedAppBar(context, favoritesProvider, theme, isDark),
              if (favoritesProvider.favorites.isNotEmpty) ...[
                _buildSearchAndFilter(context, theme, isDark),
                _buildPropertiesContent(context, theme, isDark),
              ] else
                _buildEmptyState(context, theme, isDark),
            ],
          ),
          floatingActionButton: _buildAnimatedFAB(context, favoritesProvider, theme, isDark),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildAnimatedAppBar(BuildContext context, FavoritesProvider favoritesProvider, ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [
                        theme.primaryColor.withOpacity(0.8),
                        theme.primaryColorDark,
                        Colors.black87,
                      ]
                    : [
                        theme.primaryColor.withOpacity(0.7),
                        theme.primaryColorDark,
                        theme.primaryColor.withOpacity(0.9),
                      ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _headerAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _BackgroundPatternPainter(
                            progress: _headerAnimation.value,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        );
                      },
                    ),
                  ),
                  // Content
                  Transform.translate(
                    offset: Offset(0, 50 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value.clamp(0.0, 1.0),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Hero(
                                    tag: 'favorites-icon',
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'My Favorites',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${favoritesProvider.favorites.length} ${favoritesProvider.favorites.length == 1 ? 'property' : 'properties'}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (favoritesProvider.favorites.isNotEmpty)
                                    _buildClearAllButton(context, favoritesProvider, theme),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClearAllButton(BuildContext context, FavoritesProvider favoritesProvider, ThemeData theme) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showClearAllDialog(context, favoritesProvider, theme),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.clear_all_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _searchAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _searchAnimation.value)),
            child: Opacity(
              opacity: _searchAnimation.value.clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Enhanced Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          HapticFeedback.selectionClick();
                        },
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Search your favorite properties...',
                          hintStyle: TextStyle(
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                            size: 24,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: theme.iconTheme.color?.withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    HapticFeedback.lightImpact();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Enhanced Filter and View Controls
                    Row(
                      children: [
                        Expanded(
                          child: _buildSortDropdown(theme, isDark),
                        ),
                        const SizedBox(width: 16),
                        _buildViewToggle(theme, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortDropdown(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.iconTheme.color?.withOpacity(0.7),
          ),
          style: theme.textTheme.bodyMedium,
          dropdownColor: theme.cardColor,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _sortBy = newValue;
              });
              HapticFeedback.selectionClick();
            }
          },
          items: const [
            DropdownMenuItem(value: 'recent', child: Text('Recently Added')),
            DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
            DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
            DropdownMenuItem(value: 'name', child: Text('Name A-Z')),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewButton(Icons.grid_view_rounded, true, theme),
          _buildViewButton(Icons.view_list_rounded, false, theme),
        ],
      ),
    );
  }

  Widget _buildViewButton(IconData icon, bool isGrid, ThemeData theme) {
    final isSelected = _isGridView == isGrid;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isGridView = isGrid;
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : theme.iconTheme.color?.withOpacity(0.7),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesContent(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your favorites...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: _buildErrorState(context, theme, isDark),
      );
    }

    final filteredProperties = _filteredAndSortedProperties;

    if (filteredProperties.isEmpty) {
      return SliverFillRemaining(
        child: _buildNoResultsState(context, theme, isDark),
      );
    }

    return _isGridView
        ? _buildGridView(filteredProperties, theme)
        : _buildListView(filteredProperties, theme);
  }

  Widget _buildGridView(List<Property> properties, ThemeData theme) {
    return SliverPadding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: MediaQuery.of(context).size.width > 600 ? 250 : 200,  // Larger cards on big screens
          childAspectRatio: 0.70,   // Dynamic ratio that works on all screens
          mainAxisSpacing: MediaQuery.of(context).size.width > 600 ? 24 : 16,
          crossAxisSpacing: MediaQuery.of(context).size.width > 600 ? 24 : 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildAnimatedPropertyCard(properties[index], index, theme);
          },
          childCount: properties.length,
        ),
      ),
    );
  }

  Widget _buildListView(List<Property> properties, ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    
    return SliverPadding(
      padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: isLargeScreen ? 24 : 16),
              child: _buildAnimatedPropertyCard(
                properties[index], 
                index, 
                theme, 
                isListView: true,
              ),
            );
          },
          childCount: properties.length,
        ),
      ),
    );
  }

  Widget _buildAnimatedPropertyCard(Property property, int index, ThemeData theme, {bool isListView = false}) {
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        final delay = (index * 0.1).clamp(0.0, 1.0);
        final animationValue = Curves.easeOutQuart.transform(
          (_staggerAnimation.value - delay).clamp(0.0, 1.0),
        );
        
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0),
            child: isListView 
              ? SizedBox(
                  height: MediaQuery.of(context).size.width > 600 ? 320 : 280,  // Responsive height
                  child: PropertyCard(propertyId: property.id),
                )
              : PropertyCard(propertyId: property.id),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return SliverFillRemaining(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.3 + (0.7 * value),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withOpacity(0.8),
                          theme.primaryColorDark,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              'No Favorite Properties Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start exploring properties and add them to your favorites.\nThey\'ll appear here for easy access and quick reference.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Properties'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: theme.primaryColor.withOpacity(0.5),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 50,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'No Results Found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.headlineSmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Try adjusting your search or filter criteria\nto find your favorite properties',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _sortBy = 'recent';
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear Filters'),
            style: TextButton.styleFrom(
              foregroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Something went wrong',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.headlineSmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unknown error occurred while loading your favorites',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _loadFavoriteProperties,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB(BuildContext context, FavoritesProvider favoritesProvider, ThemeData theme, bool isDark) {
    if (favoritesProvider.favorites.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              _loadFavoriteProperties();
              HapticFeedback.mediumImpact();
            },
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 12,
            label: const Text(
              'Refresh',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.refresh_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context, FavoritesProvider favoritesProvider, ThemeData theme) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Clear All Favorites',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to remove all properties from your favorites? This action cannot be undone.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              favoritesProvider.clearFavorites();
              Navigator.pop(context);
              setState(() {
                _favoriteProperties = [];
              });
              HapticFeedback.mediumImpact();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'All favorites cleared successfully',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  backgroundColor: theme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for animated background pattern
class _BackgroundPatternPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BackgroundPatternPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width * 0.8;

    // Create animated circles
    for (int i = 0; i < 3; i++) {
      final radius = (maxRadius * progress * (i + 1) / 3) % maxRadius;
      final opacity = (1 - (radius / maxRadius)).clamp(0.0, 1.0);
      
      paint.color = color.withOpacity(opacity * 0.3);
      canvas.drawCircle(
        Offset(centerX + (i * 20), centerY - (i * 15)),
        radius,
        paint,
      );
    }

    // Create floating dots
    for (int i = 0; i < 8; i++) {
      final angle = (progress * 2 * 3.14159) + (i * 0.785);
      final distance = 50 + (30 * progress);
      final x = centerX + (distance * (i / 8)) * (1 + 0.5 * progress);
      final y = centerY + (distance * (i / 8)) * (1 + 0.3 * progress);
      
      paint.color = color.withOpacity(0.4 * progress);
      canvas.drawCircle(
        Offset(x, y),
        3 * progress,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}