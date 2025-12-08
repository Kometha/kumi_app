import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final supabase = Supabase.instance.client;

  /// Validar formato de imagen permitido
  bool _esFormatoValido(String extension) {
    final formatosPermitidos = ['png', 'jpg', 'jpeg', 'heic', 'webp'];
    return formatosPermitidos.contains(extension.toLowerCase());
  }

  /// Validar tamaño de imagen (máximo 5 MB)
  Future<bool> _validarTamanio(File file) async {
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= 5.0;
  }

  /// Validar tamaño de imagen desde bytes (máximo 5 MB)
  bool _validarTamanioBytes(Uint8List bytes) {
    final sizeInMB = bytes.length / (1024 * 1024);
    return sizeInMB <= 5.0;
  }

  /// Obtener extensión del archivo
  String _obtenerExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'jpg'; // Por defecto
  }

  /// Obtener tipo MIME basado en la extensión
  String _obtenerContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Subir imagen a Supabase Storage desde File
  Future<String> uploadImage(File imageFile) async {
    try {
      // Validar formato
      final extension = _obtenerExtension(imageFile.path);
      if (!_esFormatoValido(extension)) {
        throw Exception(
            'Formato de imagen no válido. Solo se permiten: PNG, JPG, JPEG, HEIC, WEBP');
      }

      // Validar tamaño (máximo 5 MB)
      final esValido = await _validarTamanio(imageFile);
      if (!esValido) {
        throw Exception('La imagen es demasiado grande. Máximo permitido: 5 MB');
      }

      // Leer archivo como bytes
      final bytes = await imageFile.readAsBytes();
      
      // Subir usando el método de bytes
      return await uploadImageBytes(bytes, extension);
    } catch (e) {
      print('❌ [STORAGE] Error en uploadImage: $e');
      rethrow;
    }
  }

  /// Subir imagen a Supabase Storage desde bytes
  Future<String> uploadImageBytes(Uint8List bytes, String extension) async {
    try {
      // Validar formato
      if (!_esFormatoValido(extension)) {
        throw Exception(
            'Formato de imagen no válido. Solo se permiten: PNG, JPG, JPEG, HEIC, WEBP');
      }

      // Validar tamaño (máximo 5 MB)
      if (!_validarTamanioBytes(bytes)) {
        throw Exception('La imagen es demasiado grande. Máximo permitido: 5 MB');
      }

      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomStr = DateTime.now().microsecondsSinceEpoch.toString().substring(7);
      final fileName = '${timestamp}_$randomStr.$extension';
      final filePath = fileName;

      // Obtener tipo MIME
      final contentType = _obtenerContentType(extension);

      // Subir a Supabase Storage usando uploadBinary
      await supabase.storage
          .from('productos-imagenes')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: contentType,
            ),
          );

      // Obtener URL pública de la imagen
      final urlData = supabase.storage
          .from('productos-imagenes')
          .getPublicUrl(filePath);

      if (urlData.isEmpty) {
        throw Exception('No se pudo obtener la URL pública de la imagen');
      }

      print('✅ [STORAGE] Imagen subida correctamente: $urlData');
      return urlData;
    } catch (e) {
      print('❌ [STORAGE] Error en uploadImageBytes: $e');
      rethrow;
    }
  }
}

