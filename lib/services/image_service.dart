import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // Seleccionar imagen de la galería
  Future<File?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery
    );

    if (pickedFile == null) { return null; }
    
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.webp';

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      targetPath,
      format: CompressFormat.webp,
      quality: 80,
      minWidth: 500,
      minHeight: 500
    );

    if (result != null) {
      return File(result.path);
    }

    return null;
  }

  // Comprimir imagen de receta (devuelve bytes WEBP)
  Future<Uint8List?> compressRecipeImage(XFile file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.path,
      format: CompressFormat.webp,
      quality: 80,
      minWidth: 1024,
      minHeight: 1024,
    );
    return result;
  }

  // Subir la imagen a Supabase
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Nombre único para evitar confilctos
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.webp';
      final path = 'avatars/$fileName';

      await _supabase.storage.from('avatars').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Obtiene la URL para devolverla
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      
      return publicUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
}