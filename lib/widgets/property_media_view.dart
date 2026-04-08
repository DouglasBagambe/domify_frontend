import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/property_model.dart';

class PropertyMediaView extends StatefulWidget {
  final Property property;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const PropertyMediaView({
    super.key,
    required this.property,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<PropertyMediaView> createState() => _PropertyMediaViewState();
}

class _PropertyMediaViewState extends State<PropertyMediaView> {
  final PageController _mediaController = PageController();
  int _currentMediaIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.property.videos.isNotEmpty) {
      _videoController = VideoPlayerController.network(widget.property.videos[0]);
      await _videoController!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mediaController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          widget.onSwipeRight();
        } else if (details.primaryVelocity! < 0) {
          widget.onSwipeLeft();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Media View
            Expanded(
              child: PageView.builder(
                controller: _mediaController,
                itemCount: widget.property.images.length + widget.property.videos.length,
                onPageChanged: (index) {
                  setState(() => _currentMediaIndex = index);
                  if (index >= widget.property.images.length) {
                    _videoController?.play();
                    setState(() => _isVideoPlaying = true);
                  } else {
                    _videoController?.pause();
                    setState(() => _isVideoPlaying = false);
                  }
                },
                itemBuilder: (context, index) {
                  if (index < widget.property.images.length) {
                    return Image.network(
                      widget.property.images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error_outline, size: 48),
                        );
                      },
                    );
                  } else {
                    final videoIndex = index - widget.property.images.length;
                    if (_videoController?.value.isInitialized ?? false) {
                      return AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            // Media Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.property.images.length + widget.property.videos.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentMediaIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            // Property Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.property.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.location,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UGX ${widget.property.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
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
} 