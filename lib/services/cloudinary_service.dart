import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String apiKey = 'YOUR_API_KEY';
  static const String apiSecret = 'YOUR_API_SECRET';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    cloudName,
    'rent_app',
    cache: false,
  );

  Future<String> uploadImage(File imageFile) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadVideo(File videoFile) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          videoFile.path,
          resourceType: CloudinaryResourceType.Video,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    try {
      final List<String> urls = [];
      for (final file in imageFiles) {
        final url = await uploadImage(file);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Failed to upload multiple images: $e');
    }
  }

  Future<void> deleteMedia(String publicId) async {
    try {
      await _cloudinary.deleteResource(
        publicId: publicId,
        resourceType: CloudinaryResourceType.Image,
      );
    } catch (e) {
      throw Exception('Failed to delete media: $e');
    }
  }
} 