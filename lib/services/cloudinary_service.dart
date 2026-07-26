// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Shared Cloudinary upload service — single source of truth for every
/// screen that needs to upload images or voice notes. Import this instead
/// of defining a local CloudinaryService in individual screens.
class CloudinaryService {
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'zcymmion',
    'vsijyesz',
    cache: false,
  );

  /// Uploads a lost/found item photo.
  static Future<String?> uploadItemImage(File imageFile) {
    return _upload(imageFile, resourceType: CloudinaryResourceType.Image);
  }

  /// Uploads a user's profile picture.
  static Future<String?> uploadProfilePicture(File imageFile) {
    return _upload(imageFile, resourceType: CloudinaryResourceType.Image);
  }

  /// Uploads a voice message recording. Cloudinary serves audio through
  /// its "video" resource type — there's no separate "audio" type.
  static Future<String?> uploadVoiceMessage(File audioFile) {
    return _upload(audioFile, resourceType: CloudinaryResourceType.Video);
  }

  static Future<String?> _upload(
      File file, {
        required CloudinaryResourceType resourceType,
      }) async {
    try {
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: resourceType,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}