import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import 'image_carousel.dart';
import 'property_tags.dart';
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
      setState(() {
        _property = property;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_property == null) {
      return const Center(child: Text('Property not found'));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamic height based on card width
                  final cardWidth = constraints.maxWidth;
                  final imageHeight = (cardWidth * 0.75).clamp(120.0, 180.0).toDouble();
                  
                  return ImageCarousel(
                    images: _property!.images,
                    height: imageHeight,
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, child) {
                        final isFavorite = favoritesProvider.isFavorite(_property!.id);
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                          ),
                          onPressed: () {
                            favoritesProvider.toggleFavorite(_property!.id);
                          },
                        );
                      },
                    ),
                    Consumer<CompareProvider>(
                      builder: (context, compareProvider, child) {
                        final isInCompare = compareProvider.isInCompare(_property!.id);
                        final canAdd = compareProvider.compareList.length < 2 || isInCompare;
                        return IconButton(
                          icon: Icon(
                            isInCompare ? Icons.compare_arrows : Icons.compare_arrows_outlined,
                            color: isInCompare ? Theme.of(context).colorScheme.primary : Colors.white,
                          ),
                          onPressed: canAdd
                              ? () {
                                  if (isInCompare) {
                                    compareProvider.removeFromCompare(_property!.id);
                                  } else {
                                    compareProvider.addToCompare(_property!.id);
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 12 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _property!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _property!.location,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        'UGX ${_property!.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 1,
                      child: Text(
                        _property!.type.toString().split('.').last,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}