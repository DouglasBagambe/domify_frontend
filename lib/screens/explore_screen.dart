import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final Map<String, PageController> _imageControllers = {};

  List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  int _currentImageIndex = 0;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Apartment',
    'House',
    'Villa',
    'Commercial',
    'Land',
    'Studio',
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  PageController _getImageController(String id) {
    return _imageControllers.putIfAbsent(id, () => PageController());
  }

  Future<void> _loadProperties() async {
    try {
      final properties = await ApiService.getAllProperties();
      if (mounted) {
        setState(() {
          _properties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Property> get _filtered {
    if (_selectedFilter == 'All') return _properties;
    return _properties
        .where((p) =>
            p.type.toString().split('.').last.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  void _onFilterChanged(String filter) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFilter = filter;
      _currentIndex = 0;
      _currentImageIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _imageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_filtered.isEmpty) return _buildEmpty();
    return _buildFeed();
  }

  // ─── MAIN FEED ─────────────────────────────────────────────
  Widget _buildFeed() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Vertical swipe feed
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _filtered.length,
            onPageChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _currentIndex = index;
                _currentImageIndex = 0;
              });
            },
            itemBuilder: (context, index) {
              return _buildPropertySlide(_filtered[index]);
            },
          ),

          // Top: Story-style image progress bars
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildStoryBars(),
          ),

          // Top: Filter chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 28,
            left: 0,
            right: 0,
            child: _buildFilterRow(),
          ),

          // Right: TikTok action buttons
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: _buildActionColumn(),
          ),

          // Bottom: Property info
          Positioned(
            left: 0,
            right: 72,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _buildPropertyInfo(),
          ),
        ],
      ),
    );
  }

  // ─── PROPERTY SLIDE ────────────────────────────────────────
  Widget _buildPropertySlide(Property property) {
    final images = property.images;
    final controller = _getImageController(property.id);

    return GestureDetector(
      // Tap left/right sides to switch images (like Instagram Stories)
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth * 0.3) {
          _prevImage(controller, images.length);
        } else if (details.globalPosition.dx > screenWidth * 0.7) {
          _nextImage(controller, images.length);
        }
      },
      child: PageView.builder(
        controller: controller,
        itemCount: images.length,
        onPageChanged: (index) {
          setState(() => _currentImageIndex = index);
        },
        itemBuilder: (context, imgIndex) {
          return Image.network(
            images[imgIndex],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[700]!,
                child: Container(color: Colors.grey[900]),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }

  void _nextImage(PageController controller, int total) {
    if (_currentImageIndex < total - 1 && controller.hasClients) {
      controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _prevImage(PageController controller, int total) {
    if (_currentImageIndex > 0 && controller.hasClients) {
      controller.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // ─── STORY BARS (top) ──────────────────────────────────────
  Widget _buildStoryBars() {
    if (_filtered.isEmpty || _currentIndex >= _filtered.length) {
      return const SizedBox.shrink();
    }
    final imageCount = _filtered[_currentIndex].images.length;
    if (imageCount <= 1) return const SizedBox.shrink();

    return Row(
      children: List.generate(imageCount, (i) {
        return Expanded(
          child: Container(
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i <= _currentImageIndex
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }

  // ─── FILTER ROW ────────────────────────────────────────────
  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onFilterChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── ACTION COLUMN (right side, TikTok style) ──────────────
  Widget _buildActionColumn() {
    if (_filtered.isEmpty || _currentIndex >= _filtered.length) {
      return const SizedBox.shrink();
    }
    final property = _filtered[_currentIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Agent avatar
        _buildAgentAvatar(property),
        const SizedBox(height: 20),
        // Favorite
        _buildActionBtn(property),
        const SizedBox(height: 20),
        // Compare
        _buildCompareBtn(property),
        const SizedBox(height: 20),
        // Share
        _buildIconAction(
          Icons.share_rounded,
          'Share',
          () => _shareProperty(property),
        ),
        const SizedBox(height: 20),
        // Call agent
        _buildIconAction(
          Icons.call_rounded,
          'Call',
          () => _callAgent(property),
        ),
      ],
    );
  }

  Widget _buildAgentAvatar(Property property) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: NetworkImage(property.agent.photo),
              fit: BoxFit.cover,
              onError: (_, __) {},
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: -6),
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Color(0xFF178F5B),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 10),
        ),
      ],
    );
  }

  Widget _buildActionBtn(Property property) {
    return Consumer<FavoritesProvider>(
      builder: (context, fav, _) {
        final isFav = fav.isFavorite(property.id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            fav.toggleFavorite(property.id);
          },
          child: Column(
            children: [
              Icon(
                isFav ? Icons.favorite : Icons.favorite_border_rounded,
                color: isFav ? Colors.red : Colors.white,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                '${property.favorites}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompareBtn(Property property) {
    return Consumer<CompareProvider>(
      builder: (context, cmp, _) {
        final inCompare = cmp.isInCompare(property.id);
        final canAdd = cmp.compareList.length < 2 || inCompare;
        return GestureDetector(
          onTap: canAdd
              ? () {
                  HapticFeedback.mediumImpact();
                  if (inCompare) {
                    cmp.removeFromCompare(property.id);
                  } else {
                    cmp.addToCompare(property.id);
                  }
                }
              : null,
          child: Column(
            children: [
              Icon(
                inCompare ? Icons.compare_arrows : Icons.compare_arrows_outlined,
                color: inCompare ? const Color(0xFF178F5B) : Colors.white,
                size: 32,
              ),
              const SizedBox(height: 4),
              const Text(
                'Compare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROPERTY INFO (bottom, like TikTok captions) ──────────
  Widget _buildPropertyInfo() {
    if (_filtered.isEmpty || _currentIndex >= _filtered.length) {
      return const SizedBox.shrink();
    }
    final property = _filtered[_currentIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Agent name
          Row(
            children: [
              Text(
                '@${property.agent.name.replaceAll(' ', '').toLowerCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF178F5B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  property.purpose.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Title
          Text(
            property.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.location,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Price + details row
          Row(
            children: [
              // Price pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'UGX ${_formatPrice(property.price)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Property specs
              if (property.size.bedrooms != null && property.size.bedrooms! > 0)
                _buildSpecChip(Icons.bed_outlined, '${property.size.bedrooms}'),
              if (property.size.bathrooms != null && property.size.bathrooms! > 0)
                _buildSpecChip(Icons.bathtub_outlined, '${property.size.bathrooms}'),
              _buildSpecChip(Icons.square_foot, '${property.size.totalArea}'),
            ],
          ),
          const SizedBox(height: 12),

          // Scroll indicator
          Row(
            children: [
              Text(
                '${_currentIndex + 1}/${_filtered.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
              Text(
                'Swipe for more',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────
  void _shareProperty(Property property) async {
    final text =
        '🏠 Check out this property on Domify!\n${property.title}\n📍 ${property.location}\n💰 UGX ${_formatPrice(property.price)}';
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callAgent(Property property) async {
    final uri = Uri.parse('tel:${property.agent.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)}B';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  // ─── STATE SCREENS ─────────────────────────────────────────
  Widget _buildLoading() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading properties...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadProperties();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No properties found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _onFilterChanged('All'),
              child: Text(
                'Clear filters',
                style: TextStyle(
                  color: const Color(0xFF178F5B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}