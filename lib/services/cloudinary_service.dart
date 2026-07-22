import 'package:cloudinary_public/cloudinary_public.dart';

import 'dart:io';

class CloudinaryService {
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'zcymmion',
    'vsijyesz',
    cache: false,
  );

  static Future<String?> uploadItemImage(File imageFile) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}