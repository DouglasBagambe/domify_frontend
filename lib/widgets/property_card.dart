import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/property_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import 'image_carousel.dart';
import '../services/api_service.dart';

class PropertyCard extends StatefulWidget {
  final String propertyId;

  const PropertyCard({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  Property? _property;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    try {
      final property = await ApiService.getProperty(widget.propertyId);
      if (mounted) {
        setState(() {
          _property = property;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_error != null || _property == null) {
      return _buildErrorState();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final textSectionHeight = availableHeight * 0.32;
          final imageSectionHeight = availableHeight - textSectionHeight;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              SizedBox(
                height: imageSectionHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageCarousel(
                      images: _property!.images,
                    ),
                    // Action buttons
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFavoriteButton(),
                          _buildCompareButton(),
                        ],
                      ),
                    ),
                    // Purpose badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _purposeColor(_property!.purpose.toString().split('.').last),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _property!.purpose.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text section
              SizedBox(
                height: textSectionHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _property!.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              _property!.location,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'UGX ${_formatPrice(_property!.price)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(_property!.id);
        return GestureDetector(
          onTap: () => favoritesProvider.toggleFavorite(_property!.id),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompareButton() {
    return Consumer<CompareProvider>(
      builder: (context, compareProvider, child) {
        final isInCompare = compareProvider.isInCompare(_property!.id);
        final canAdd = compareProvider.compareList.length < 2 || isInCompare;
        return GestureDetector(
          onTap: canAdd
              ? () {
                  if (isInCompare) {
                    compareProvider.removeFromCompare(_property!.id);
                  } else {
                    compareProvider.addToCompare(_property!.id);
                  }
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInCompare ? Icons.compare_arrows : Icons.compare_arrows_outlined,
              color: isInCompare ? Colors.cyanAccent : Colors.white,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textHeight = constraints.maxHeight * 0.32;
            final imageHeight = constraints.maxHeight - textHeight;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: imageHeight, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 12, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(width: 120, height: 10, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 4),
            Text(
              'Failed to load',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Color _purposeColor(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'sale':
        return const Color(0xFF178F5B);
      case 'rent':
        return const Color(0xFF1A3C6E);
      case 'shortstay':
        return const Color(0xFFA17324);
      default:
        return Colors.grey;
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
}