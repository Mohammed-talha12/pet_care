import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ImageHelper {
  static final _picker = ImagePicker();

  // 📸 Pick an image from Gallery
  static Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) return File(image.path);
    return null;
  }

  // ☁️ Upload to Supabase Storage
  static Future<String?> uploadImage(File file, String bucket) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final path = 'uploads/$fileName';

      await Supabase.instance.client.storage.from(bucket).upload(path, file);

      // Get the Public URL to save in our database
      final String publicUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}