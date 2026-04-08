import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

class AllPropertiesScreen extends StatefulWidget {
  final String title;
  final List<Property> initialProperties;
  final bool showFeaturedOnly;

  const AllPropertiesScreen({
    super.key,
    required this.title,
    required this.initialProperties,
    this.showFeaturedOnly = false,
  });

  @override
  State<AllPropertiesScreen> createState() => _AllPropertiesScreenState();
}

class _AllPropertiesScreenState extends State<AllPropertiesScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Property> _filteredProperties = [];
  bool _isSearching = false;

  // Filter states
  PropertyType? _selectedType;
  PropertyPurpose? _selectedPurpose;
  RangeValues _priceRange = const RangeValues(0, 1000000000);
  List<String> _selectedAmenities = [];
  String? _selectedLocation;
  int? _minBedrooms;
  int? _minBathrooms;

  @override
  void initState() {
    super.initState();
    _properties = widget.initialProperties;
    _filteredProperties = widget.initialProperties;
    _scrollController.addListener(_onScroll);
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreProperties();
    }
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

  Future<void> _loadMoreProperties() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      final properties = await ApiService.getRecentProperties();
      setState(() {
        _properties.addAll(properties);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more properties: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProperties = _properties.where((property) {
        // Type filter
        if (_selectedType != null && property.type != _selectedType) {
          return false;
        }

        // Purpose filter
        if (_selectedPurpose != null && property.purpose != _selectedPurpose) {
          return false;
        }

        // Price range filter
        if (property.price < _priceRange.start || property.price > _priceRange.end) {
          return false;
        }

        // Location filter
        if (_selectedLocation != null && property.location != _selectedLocation) {
          return false;
        }

        // Bedrooms filter
        if (_minBedrooms != null && (property.size.bedrooms ?? 0) < _minBedrooms!) {
          return false;
        }

        // Bathrooms filter
        if (_minBathrooms != null && (property.size.bathrooms ?? 0) < _minBathrooms!) {
          return false;
        }

        // Amenities filters
        if (_selectedAmenities.isNotEmpty) {
          for (final amenity in _selectedAmenities) {
            if (!property.amenities.contains(amenity)) {
              return false;
            }
          }
        }

        // Search text filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          return property.title.toLowerCase().contains(searchLower) ||
              property.location.toLowerCase().contains(searchLower) ||
              property.description.toLowerCase().contains(searchLower);
        }

        return true;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedPurpose = null;
                        _priceRange = const RangeValues(0, 1000000000);
                        _selectedAmenities = [];
                        _selectedLocation = null;
                        _minBedrooms = null;
                        _minBathrooms = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Property Type
              Text(
                'Property Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PropertyType.values.map((type) {
                  return FilterChip(
                    label: Text(type.toString().split('.').last),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Property Purpose
              Text(
                'Purpose',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PropertyPurpose.values.map((purpose) {
                  return FilterChip(
                    label: Text(purpose.toString().split('.').last),
                    selected: _selectedPurpose == purpose,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPurpose = selected ? purpose : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Price Range
              Text(
                'Price Range',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000000000,
                divisions: 100,
                labels: RangeLabels(
                  'UGX ${_priceRange.start.round()}',
                  'UGX ${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() => _priceRange = values);
                },
              ),
              const SizedBox(height: 16),
              // Bedrooms & Bathrooms
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Min Bedrooms',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: _minBedrooms,
                          isExpanded: true,
                          hint: const Text('Any'),
                          items: [1, 2, 3, 4, 5].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text('$value+'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _minBedrooms = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Min Bathrooms',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: _minBathrooms,
                          isExpanded: true,
                          hint: const Text('Any'),
                          items: [1, 2, 3, 4].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text('$value+'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _minBathrooms = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Amenities
              Text(
                'Amenities',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'wifi',
                  'parking',
                  'pool',
                  'gym',
                  'security',
                  'furnished',
                ].map((amenity) {
                  return FilterChip(
                    label: Text(amenity),
                    selected: _selectedAmenities.contains(amenity),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search properties...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _applyFilters();
              },
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProperties.length} properties found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Filter'),
                ),
              ],
            ),
          ),
          // Properties Grid
          Expanded(
            child: _filteredProperties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No properties found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filteredProperties.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredProperties.length) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final property = _filteredProperties[index];
                      return PropertyCard(
                        propertyId: property.id,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 