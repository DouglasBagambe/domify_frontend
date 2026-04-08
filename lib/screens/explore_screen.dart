import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final PageController _verticalPageController = PageController();
  final Map<String, PageController> _horizontalPageControllers = {};
  
  late AnimationController _filterAnimationController;
  late AnimationController _actionButtonsController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  
  late Animation<double> _filterSlideAnimation;
  late Animation<double> _actionButtonsAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _backgroundAnimation;

  List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  String _selectedLocation = 'All Locations';
  double _minPrice = 0;
  double _maxPrice = 10000000;
  int _currentPropertyIndex = 0;
  int _currentMediaIndex = 0;
  
  bool _showFilters = false;
  bool _showAdvancedFilters = false;
  
  // Helper method to get or create PageController for a property
  PageController _getHorizontalPageController(String propertyId) {
    return _horizontalPageControllers.putIfAbsent(propertyId, () => PageController());
  }

  final List<String> _propertyTypes = [
    'All', 'Apartment', 'House', 'Villa', 'Commercial', 'Studio', 'Bungalow', 'Duplex', 'Penthouse'
  ];

  final List<String> _locations = [
    'All Locations', 'Kampala', 'Entebbe', 'Wakiso', 'Mukono', 'Jinja', 'Mbarara', 'Gulu', 'Masaka'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProperties();
    
    // Hide system UI for full immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _actionButtonsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _filterSlideAnimation = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.elasticOut,
    ));

    _actionButtonsAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _actionButtonsController,
      curve: Curves.bounceOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.deepPurple.shade900,
    ).animate(_backgroundController);

    // Start animations
    _filterAnimationController.forward();
    _actionButtonsController.forward();
    _pulseController.repeat(reverse: true);
    _backgroundController.repeat(reverse: true);
  }

  Future<void> _loadProperties() async {
    try {
      final properties = await ApiService.getRecentProperties();
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Property> get _filteredProperties {
    var filtered = _properties.where((property) {
      // Type filter
      bool typeMatch = _selectedFilter == 'All' || 
        property.type.toString().split('.').last.toLowerCase() == _selectedFilter.toLowerCase();
      
      // Location filter
      bool locationMatch = _selectedLocation == 'All Locations' || 
        property.location.toLowerCase().contains(_selectedLocation.toLowerCase());
      
      // Price filter
      bool priceMatch = property.price >= _minPrice && property.price <= _maxPrice;
      
      return typeMatch && locationMatch && priceMatch;
    }).toList();
    
    return filtered;
  }

  void _onVerticalSwipe(DragEndDetails details) {
    HapticFeedback.lightImpact();
    if (details.primaryVelocity! > 0) {
      _onSwipeDown();
    } else if (details.primaryVelocity! < 0) {
      _onSwipeUp();
    }
  }

  void _onHorizontalSwipe(DragEndDetails details) {
    HapticFeedback.selectionClick();
    if (details.primaryVelocity! > 0) {
      _previousMedia();
    } else if (details.primaryVelocity! < 0) {
      _nextMedia();
    }
  }

  void _onSwipeUp() {
    if (_currentPropertyIndex < _filteredProperties.length - 1) {
      setState(() {
        _currentPropertyIndex++;
        _currentMediaIndex = 0;
      });
      _verticalPageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      // Reset horizontal page for new property
      if (_filteredProperties.isNotEmpty && _currentPropertyIndex < _filteredProperties.length) {
        final currentProperty = _filteredProperties[_currentPropertyIndex];
        _getHorizontalPageController(currentProperty.id).animateToPage(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onSwipeDown() {
    if (_currentPropertyIndex > 0) {
      setState(() {
        _currentPropertyIndex--;
        _currentMediaIndex = 0;
      });
      _verticalPageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      // Reset horizontal page for new property
      if (_filteredProperties.isNotEmpty && _currentPropertyIndex >= 0) {
        final currentProperty = _filteredProperties[_currentPropertyIndex];
        _getHorizontalPageController(currentProperty.id).animateToPage(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _nextMedia() {
    if (_currentPropertyIndex < _filteredProperties.length) {
      final property = _filteredProperties[_currentPropertyIndex];
      final totalMedia = property.images.length + property.videos.length;
      if (_currentMediaIndex < totalMedia - 1) {
        setState(() => _currentMediaIndex++);
        _getHorizontalPageController(property.id).nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousMedia() {
    if (_currentMediaIndex > 0 && _currentPropertyIndex < _filteredProperties.length) {
      final property = _filteredProperties[_currentPropertyIndex];
      setState(() => _currentMediaIndex--);
      _getHorizontalPageController(property.id).previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _shareProperty(Property property) async {
    HapticFeedback.mediumImpact();
    final url = 'https://rentapp.ug/property/${property.id}';
    final text = '🏠 Check out this AMAZING property!\n${property.title}\n📍 ${property.location}\n💰 UGX ${property.price.toStringAsFixed(0)}';
    
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('$text\n\n$url')}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateHome() {
    HapticFeedback.heavyImpact();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue, Colors.pink],
                        ),
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 40),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading Epic Properties...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Oops! $_error', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProperties,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredProperties.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'No Epic Properties Found!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Try adjusting your filters',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundAnimation.value,
          body: Stack(
            children: [
              // Main content area
              GestureDetector(
                onVerticalDragEnd: _onVerticalSwipe,
                onHorizontalDragEnd: _onHorizontalSwipe,
                child: PageView.builder(
                  controller: _verticalPageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _filteredProperties.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPropertyIndex = index;
                      _currentMediaIndex = 0;
                    });
                    // Reset horizontal page for new property
                    if (index < _filteredProperties.length) {
                      final property = _filteredProperties[index];
                      _getHorizontalPageController(property.id).animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  itemBuilder: (context, index) {
                    final property = _filteredProperties[index];
                    return _buildPropertyCard(property);
                  },
                ),
              ),
              
              // Animated filter bar
              AnimatedBuilder(
                animation: _filterSlideAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: MediaQuery.of(context).padding.top + _filterSlideAnimation.value,
                    left: 16,
                    right: 16,
                    child: _buildFilterBar(),
                  );
                },
              ),
              
              // Property progress indicator
              Positioned(
                top: MediaQuery.of(context).padding.top + 120,
                right: 16,
                child: _buildProgressIndicator(),
              ),
              
              // Epic action buttons
              AnimatedBuilder(
                animation: _actionButtonsAnimation,
                builder: (context, child) {
                  return Positioned(
                    right: 16,
                    bottom: 40,
                    child: Transform.scale(
                      scale: _actionButtonsAnimation.value,
                      child: _buildActionButtons(),
                    ),
                  );
                },
              ),
              
              // // Home button (Epic style)
              // Positioned(
              //   right: 16,
              //   bottom: 50,
              //   child: _buildHomeButton(),
              // ),
              // 
              
              // Advanced filters overlay
              if (_showAdvancedFilters) _buildAdvancedFiltersOverlay(),
            ],
          ),
        );
      },
    );
  }
 
  Widget _buildFilterBar() {
    if (!_showAdvancedFilters) return const SizedBox.shrink();
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.purple.withOpacity(0.6),
            Colors.blue.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _propertyTypes.length,
              itemBuilder: (context, index) {
                final filter = _propertyTypes[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedFilter = filter;
                            _currentPropertyIndex = 0;
                          });
                          _verticalPageController.animateToPage(0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
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

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.8), Colors.purple.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${_currentPropertyIndex + 1}/${_filteredProperties.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (_currentPropertyIndex < _filteredProperties.length)
            Text(
              '${_currentMediaIndex + 1}/${_filteredProperties[_currentPropertyIndex].images.length + _filteredProperties[_currentPropertyIndex].videos.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentPropertyIndex >= _filteredProperties.length) return Container();
    final property = _filteredProperties[_currentPropertyIndex];
    return Column(
      children: [
        // Home button (top only)
        _buildEpicActionButton(
          icon: Icons.home,
          label: 'Home',
          gradient: [Colors.orange, Colors.deepOrange],
          onTap: _navigateHome,
        ),
        const SizedBox(height: 12),
        // Favorite button
        Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            final isFavorite = favoritesProvider.isFavorite(property.id);
            return _buildEpicActionButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              label: '${property.favorites}',
              gradient: isFavorite 
                ? [Colors.red, Colors.pink] 
                : [Colors.white.withOpacity(0.3), Colors.grey.withOpacity(0.3)],
              onTap: () {
                HapticFeedback.heavyImpact();
                favoritesProvider.toggleFavorite(property.id);
              },
            );
          },
        ),
        const SizedBox(height: 12),
        // Compare button
        Consumer<CompareProvider>(
          builder: (context, compareProvider, child) {
            final isInCompare = compareProvider.isInCompare(property.id);
            final canAdd = compareProvider.compareList.length < 2 || isInCompare;
            return _buildEpicActionButton(
              icon: isInCompare ? Icons.compare_arrows : Icons.compare_arrows_outlined,
              label: 'Compare',
              gradient: isInCompare 
                ? [Colors.blue, Colors.cyan] 
                : [Colors.white.withOpacity(0.3), Colors.grey.withOpacity(0.3)],
              onTap: canAdd ? () {
                HapticFeedback.heavyImpact();
                if (isInCompare) {
                  compareProvider.removeFromCompare(property.id);
                } else {
                  compareProvider.addToCompare(property.id);
                }
              } : null,
            );
          },
        ),
        const SizedBox(height: 12),
        // Share button
        _buildEpicActionButton(
          icon: Icons.share,
          label: 'Share',
          gradient: [Colors.green, Colors.teal],
          onTap: () => _shareProperty(property),
        ),
        const SizedBox(height: 12),
        // Filter button
        _buildEpicActionButton(
          icon: Icons.tune,
          label: 'Filter',
          gradient: [Colors.purple, Colors.deepPurple],
          onTap: () {
            HapticFeedback.mediumImpact();
            _showFilterModal();
          },
        ),
      ],
    );
  }

  Widget _buildEpicActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: onTap != null ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Filter Properties',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Property Type
                  const Text('Type', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _propertyTypes.map((type) {
                      final isSelected = _selectedFilter == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: Colors.purple,
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          setState(() => _selectedFilter = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Location
                  const Text('Location', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _locations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLocation = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Price Range
                  const Text('Price Range', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 10000000,
                    divisions: 100,
                    labels: RangeLabels(
                      'UGX ${_minPrice.toInt()}',
                      'UGX ${_maxPrice.toInt()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget _buildHomeButton() {
  //   return AnimatedBuilder(
  //     animation: _pulseAnimation,
  //     builder: (context, child) {
  //       return GestureDetector(
  //         onTap: () {
  //           HapticFeedback.heavyImpact();
  //           Navigator.of(context).maybePop();
  //         },
  //         child: Transform.scale(
  //           scale: _pulseAnimation.value * 0.9 + 0.1,
  //           child: Container(
  //             width: 60,
  //             height: 60,
  //             decoration: BoxDecoration(
  //               gradient: const LinearGradient(
  //                 colors: [Colors.orange, Colors.deepOrange],
  //               ),
  //               shape: BoxShape.circle,
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.orange.withOpacity(0.6),
  //                   blurRadius: 20,
  //                   spreadRadius: 3,
  //                 ),
  //               ],
  //             ),
  //             child: const Icon(Icons.home, color: Colors.white, size: 28),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildPropertyCard(Property property) {
    final totalMedia = property.images.length + property.videos.length;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Media carousel
          PageView.builder(
            controller: _getHorizontalPageController(property.id),
            itemCount: totalMedia,
            onPageChanged: (index) {
              setState(() => _currentMediaIndex = index);
            },
            itemBuilder: (context, mediaIndex) {
              if (mediaIndex < property.images.length) {
                return _buildImageCard(property.images[mediaIndex]);
              } else {
                return _buildVideoCard();
              }
            },
          ),
          
          // Epic gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          
          // Media indicators
          if (totalMedia > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 180,
              left: 20,
              right: 80,
              child: _buildMediaIndicators(totalMedia),
            ),
          
          // Property info with epic styling
          Positioned(
            bottom: 0,
            left: 0,
            right: 100,
            child: _buildPropertyInfo(property),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Hero(
      tag: imageUrl,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            onError: (error, stackTrace) {},
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, color: Colors.white, size: 80),
            SizedBox(height: 16),
            Text(
              'Video Content',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaIndicators(int totalMedia) {
    return Row(
      children: List.generate(totalMedia, (index) {
        final isActive = index == _currentMediaIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 4,
          width: isActive ? 20 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.6),
                blurRadius: 8,
              ),
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildPropertyInfo(Property property) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with epic styling
          Text(
            property.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Location with icon
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  property.location,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Price with epic styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Colors.amber],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'UGX ${property.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFiltersOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade800, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Location filter
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: Colors.purple.shade800,
                style: const TextStyle(color: Colors.white),
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLocation = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              
              // Price range
              const Text('Price Range', style: TextStyle(color: Colors.white, fontSize: 16)),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 10000000,
                divisions: 100,
                labels: RangeLabels(
                  'UGX ${_minPrice.toInt()}',
                  'UGX ${_maxPrice.toInt()}',
                ),
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              const SizedBox(height: 20),
              
              // Close button
              ElevatedButton(
                onPressed: () {
                  setState(() => _showAdvancedFilters = false);
                  HapticFeedback.mediumImpact();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _verticalPageController.dispose();
    // Dispose all horizontal page controllers
    for (final controller in _horizontalPageControllers.values) {
      controller.dispose();
    }
    _horizontalPageControllers.clear();
    _filterAnimationController.dispose();
    _actionButtonsController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}