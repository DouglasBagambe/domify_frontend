import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/property_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import '../providers/history_provider.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';
import 'stay_booking_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM PROPERTY DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Property _property;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    try {
      final property = await ApiService.getPropertyById(widget.propertyId);
      setState(() {
        _property = property;
        _isLoading = false;
      });
      // Record this view in history
      if (mounted) {
        context.read<HistoryProvider>().recordView(
          ViewedProperty(
            id: property.id,
            title: property.title,
            location: property.location,
            imageUrl: property.images.isNotEmpty ? property.images.first : '',
            price: property.price,
            purpose: property.purpose.toString().split('.').last,
            viewedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('park')) return Icons.local_parking_rounded;
    if (lower.contains('security') || lower.contains('guard')) return Icons.security_rounded;
    if (lower.contains('ac') || lower.contains('air conditioning') || lower.contains('cooling')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('pool') || lower.contains('swim')) return Icons.pool_rounded;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_rounded;
    if (lower.contains('kitchen')) return Icons.soup_kitchen_rounded;
    if (lower.contains('tv') || lower.contains('cable')) return Icons.tv_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Property Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── Premium Floating App Bar With Image Carousel ───────────────────
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: cs.surface,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Compare
              Consumer<CompareProvider>(
                builder: (context, compareProvider, child) {
                  final isInCompare = compareProvider.isInCompare(_property.id);
                  final canAdd = compareProvider.canAddMore() || isInCompare;
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInCompare ? Icons.balance_rounded : Icons.balance_outlined,
                        color: isInCompare ? cs.primary : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: canAdd
                        ? () {
                            if (isInCompare) {
                              compareProvider.removeFromCompare(_property.id);
                            } else {
                              compareProvider.addToCompare(_property.id);
                            }
                          }
                        : null,
                  );
                },
              ),
              // Share
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  final String shareText =
                      '🏠 Check out this property on dnb Homes!\n\n'
                      '${_property.title}\n'
                      '📍 ${_property.location}\n'
                      '💰 ${_property.price.toStringAsFixed(0)} UGX\n\n'
                      'View it here: https://domify.nilebitlabs.com/property/${_property.id}';
                  Share.share(
                    shareText,
                    subject: '${_property.title} — dnb Homes',
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: _property.images.length,
                    onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                    itemBuilder: (context, index) {
                      return Image.network(
                        _property.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.secondaryContainer,
                          child: Icon(Icons.image_outlined, size: 48, color: cs.secondary),
                        ),
                      );
                    },
                  ),
                  // Bottom subtle gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  // Slide counter indicator
                  Positioned(
                    bottom: 24,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${_property.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Detailed Content Sheet ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _property.title,
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 15, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _property.location,
                                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'UGX',
                            style: tt.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            _fmtPrice(_property.price),
                            style: tt.headlineSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Badges (Type & Purpose)
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.home_outlined,
                        label: _property.type.toString().split('.').last,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.sell_outlined,
                        label: _property.purpose.toString().split('.').last,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About this Property',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _property.description,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Amenities list
                  Text(
                    'Amenities Offered',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _property.amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outline.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAmenityIcon(amenity),
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              amenity,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),

                  // Premium Agent Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.outline.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Listing Agent',
                          style: tt.labelLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.outline.withOpacity(0.2), width: 1.5),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/dnblogolight.jpg'),
                                  fit: BoxFit.cover,
                                  alignment: Alignment(0.18, 0.0), // Shift right to center the logo perfectly
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'dnb',
                                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Official Listing Agent',
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri(scheme: 'tel', path: '0747877740');
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                },
                                icon: const Icon(Icons.phone_outlined, size: 18),
                                label: const Text('Call Agent'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final message = 'Hello dnb, I am interested in: ${_property.title}';
                                  final uri = Uri.parse('https://wa.me/256747877740?text=${Uri.encodeComponent(message)}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" fill="white"><path d="M380.9 97.1C339 55.1 283.2 32 223.9 32c-122.4 0-222 99.6-222 222 0 39.1 10.2 77.3 29.6 111L0 480l117.7-30.9c32.4 17.7 68.9 27 106.1 27h.1c122.3 0 224.1-99.6 224.1-222 0-59.3-25.2-115-67.1-157zm-157 341.6c-33.2 0-65.7-8.9-94-25.7l-6.7-4-69.8 18.3L72 359.2l-4.4-7c-18.5-29.4-28.2-63.3-28.2-98.2 0-101.7 82.8-184.5 184.6-184.5 49.3 0 95.6 19.2 130.4 54.1 34.8 34.9 56.2 81.2 56.1 130.5 0 101.8-84.9 184.6-186.6 184.6zm101.2-138.2c-5.5-2.8-32.8-16.2-37.9-18-5.1-1.9-8.8-2.8-12.5 2.8-3.7 5.6-14.3 18-17.6 21.8-3.2 3.7-6.5 4.2-12 1.4-32.6-16.3-54-29.1-75.5-66-5.7-9.8 5.7-9.1 16.3-30.3 1.8-3.7.9-6.9-.5-9.7-1.4-2.8-12.5-30.1-17.1-41.2-4.5-10.8-9.1-9.3-12.5-9.5-3.2-.2-6.9-.2-10.6-.2-3.7 0-9.7 1.4-14.8 6.9-5.1 5.6-19.4 19-19.4 46.3 0 27.3 19.9 53.7 22.6 57.4 2.8 3.7 39.1 59.7 94.8 83.8 35.2 15.2 49 16.5 66.6 13.9 10.7-1.6 32.8-13.4 37.4-26.4 4.6-13 4.6-24.1 3.2-26.4-1.3-2.5-5-3.9-10.5-6.6z"/></svg>',
                                  width: 17,
                                  height: 17,
                                ),
                                label: const Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outline.withOpacity(0.12))),
        ),
        child: Row(
          children: [
            // Favorites shortcut
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  final isFav = favoritesProvider.isFavorite(_property.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border_rounded,
                      color: isFav ? Colors.red.shade600 : cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      if (isFav) {
                        favoritesProvider.removeFavorite(_property.id);
                      } else {
                        favoritesProvider.addFavorite(_property.id);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // Compare shortcut
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Consumer<CompareProvider>(
                builder: (context, compareProvider, child) {
                  final isInCompare = compareProvider.isInCompare(_property.id);
                  final canAdd = compareProvider.canAddMore() || isInCompare;
                  return IconButton(
                    icon: Icon(
                      isInCompare ? Icons.balance_rounded : Icons.balance_outlined,
                      color: isInCompare
                          ? cs.primary
                          : canAdd
                              ? cs.onSurfaceVariant
                              : cs.onSurfaceVariant.withOpacity(0.38),
                    ),
                    onPressed: canAdd
                        ? () {
                            if (isInCompare) {
                              compareProvider.removeFromCompare(_property.id);
                            } else {
                              compareProvider.addToCompare(_property.id);
                            }
                          }
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            // Primary Booking Action
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _buildMoreActionsSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Book Property',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── More Actions Bottom Sheet ────────────────────────────────────────────
  Widget _buildMoreActionsSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Booking Type',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            // Schedule Viewing
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule_rounded, color: cs.primary),
              ),
              title: const Text('Schedule Viewing'),
              subtitle: const Text('Book an in-person viewing'),
              trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      property: _property,
                      bookingType: BookingType.viewing,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 64),
            // Book Your Stay
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hotel_rounded, color: Colors.orange.shade700),
              ),
              title: const Text('Book Your Stay'),
              subtitle: const Text('Reserve this property now'),
              trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StayBookingScreen(property: _property),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Premium Info Chip Helper ─────────────────────────────────────────────
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(0)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
