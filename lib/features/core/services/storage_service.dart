import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  /// Picks an image and uploads it to the specified bucket
  Future<String?> uploadImage(String bucketName) async {
    final ImagePicker picker = ImagePicker();
    
    // 1. Pick the image
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compressing to save storage space
    );

    if (image == null) return null;

    final file = File(image.path);
    final fileExt = image.path.split('.').last;
    final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
    final filePath = fileName;

    try {
      // 2. Upload to Supabase Storage
      await _supabase.storage.from(bucketName).upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 3. Get the Public URL
      final String publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }
}