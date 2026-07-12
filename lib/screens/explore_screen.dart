import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import '../providers/settings_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'property_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final Map<String, PageController> _imageControllers = {};
  final Map<String, VideoPlayerController> _videoControllers = {};

  bool _showHeartOverlay = false;
  double _heartX = 0.0;
  double _heartY = 0.0;

  void _triggerDoubleTapLike(Offset localPosition, Property property) {
    if (!mounted) return;
    final fav = Provider.of<FavoritesProvider>(context, listen: false);
    if (!fav.isFavorite(property.id)) {
      fav.toggleFavorite(property.id);
      HapticFeedback.heavyImpact();
    }
    setState(() {
      _showHeartOverlay = true;
      _heartX = localPosition.dx;
      _heartY = localPosition.dy;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showHeartOverlay = false;
        });
      }
    });
  }

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
        // Sort: properties with videos come first
        final withVideos =
            properties.where((p) => p.videos.isNotEmpty).toList();
        final withoutVideos =
            properties.where((p) => p.videos.isEmpty).toList();
        setState(() {
          _properties = [...withVideos, ...withoutVideos];
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
    for (final v in _videoControllers.values) {
      v.dispose();
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
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: _buildFilterRow(),
          ),

          // Right: TikTok action buttons
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 120,
            child: _buildActionColumn(),
          ),

          // Bottom: Property info
          Positioned(
            left: 0,
            right: 72,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: _buildPropertyInfo(),
          ),
        ],
      ),
    );
  }

  // ─── PROPERTY SLIDE ────────────────────────────────────────
  Widget _buildPropertySlide(Property property) {
    final images = property.images;
    final videos = property.videos;
    final hasVideo = videos.isNotEmpty;
    final controller = _getImageController(property.id);

    // Total media: video first (if any), then images
    final totalMedia = (hasVideo ? 1 : 0) + images.length;

    return GestureDetector(
      onDoubleTapDown: (details) {
        _triggerDoubleTapLike(details.localPosition, property);
      },
      onDoubleTap: () {},
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PropertyDetailScreen(propertyId: property.id),
          ),
        );
      },
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth * 0.3) {
          _prevImage(controller, totalMedia);
        } else if (details.globalPosition.dx > screenWidth * 0.7) {
          _nextImage(controller, totalMedia);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: controller,
            itemCount: totalMedia,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, imgIndex) {
              // First item is video if available
              if (hasVideo && imgIndex == 0) {
                return _buildVideoSlide(videos[0], property.id);
              }
              final imageIndex = hasVideo ? imgIndex - 1 : imgIndex;
              return Image.network(
                images[imageIndex],
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
                    child:
                        Icon(Icons.broken_image, color: Colors.grey, size: 48),
                  ),
                ),
              );
            },
          ),
          // Dark bottom & top overlay to protect white text contrast
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.80),
                  ],
                  stops: const [0.0, 0.20, 0.50, 1.0],
                ),
              ),
            ),
          ),
          // Live heart indicator
          if (_showHeartOverlay)
            Positioned(
              left: _heartX - 50,
              top: _heartY - 50,
              child: const AnimatedHeartOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoSlide(String videoUrl, String propertyId) {
    if (!_videoControllers.containsKey(propertyId)) {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[propertyId] = ctrl;
      ctrl.initialize().then((_) {
        if (mounted) {
          ctrl.setLooping(true);
          ctrl.play();
          setState(() {});
        }
      });
    }
    final ctrl = _videoControllers[propertyId]!;
    if (!ctrl.value.isInitialized) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[700]!,
        child: Container(color: Colors.grey[900]),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width,
            height: ctrl.value.size.height,
            child: VideoPlayer(ctrl),
          ),
        ),
        // Video play/pause indicator
        Positioned(
          bottom: 80,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('VIDEO TOUR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
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
        // Agent logo (DNB logo asset)
        _buildAgentAvatar(property),
        const SizedBox(height: 20),
        // Eye (View details)
        _buildIconAction(
          Icons.visibility_rounded,
          'Details',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(propertyId: property.id),
              ),
            );
          },
        ),
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
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/dnblogolight.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildActionBtn(Property property) {
    return Consumer<FavoritesProvider>(
      builder: (context, fav, _) {
        final isFav = fav.isFavorite(property.id);
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                fav.toggleFavorite(property.id);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.45),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? Colors.red : Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFav ? 'Saved' : 'Save',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: Colors.black87, blurRadius: 4),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompareBtn(Property property) {
    return Consumer<CompareProvider>(
      builder: (context, cmp, _) {
        final inCompare = cmp.isInCompare(property.id);
        final canAdd = cmp.compareList.length < 2 || inCompare;
        return Column(
          children: [
            GestureDetector(
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
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.45),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Icon(
                  inCompare ? Icons.balance_rounded : Icons.balance_outlined,
                  color: inCompare ? const Color(0xFF10B981) : Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Compare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: Colors.black87, blurRadius: 4),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.45),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }

  // ─── PROPERTY INFO (bottom, like TikTok captions) ──────────
  Widget _buildPropertyInfo() {
    if (_filtered.isEmpty || _currentIndex >= _filtered.length) {
      return const SizedBox.shrink();
    }
    final property = _filtered[_currentIndex];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Purpose Badge (sale/rent)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  property.purpose.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Property Title
          Text(
            property.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1.5)),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFFF87171), size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.location,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1.5)),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Price + Amenities Row
          Row(
            children: [
              // Price Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  context.read<SettingsProvider>().formatPrice(property.price),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Amenities
              if (property.size.bedrooms != null && property.size.bedrooms! > 0)
                _buildSpecChip(Icons.bed_rounded, '${property.size.bedrooms} Bed'),
              if (property.size.bathrooms != null && property.size.bathrooms! > 0)
                _buildSpecChip(Icons.bathtub_rounded, '${property.size.bathrooms} Bath'),
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
  void _shareProperty(Property property) {
    final String shareText =
        '🏠 dnb Homes Tour: Discover this property!\n\n'
        '${property.title}\n'
        '📍 ${property.location}\n'
        '💰 ${context.read<SettingsProvider>().formatPrice(property.price)}\n\n'
        'View it here: https://domify.nilebitlabs.com/property/${property.id}';
    Share.share(
      shareText,
      subject: '${property.title} — dnb Homes Feed',
    );
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

class AnimatedHeartOverlay extends StatefulWidget {
  const AnimatedHeartOverlay({super.key});

  @override
  State<AnimatedHeartOverlay> createState() => _AnimatedHeartOverlayState();
}

class _AnimatedHeartOverlayState extends State<AnimatedHeartOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_animController);
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_animController);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.red,
              size: 100,
              shadows: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}