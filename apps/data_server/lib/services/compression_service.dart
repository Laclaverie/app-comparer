import 'dart:io';
import 'package:image/image.dart' as img;

class CompressionService {
  static const String _originalPath = 'assets/images/original';
  static const String _compressedPath = 'assets/images/compressed';
  static const String _thumbnailPath = 'assets/images/thumbnails';
  
  static const int _maxWidth = 800;
  static const int _maxHeight = 600;
  static const int _quality = 85;
  static const int _thumbnailSize = 150;

  Future<void> initDirectories() async {
    await Directory(_originalPath).create(recursive: true);
    await Directory(_compressedPath).create(recursive: true);
    await Directory(_thumbnailPath).create(recursive: true);
  }

  Future<String> compressImage(File originalFile, String fileName) async {
    await initDirectories();
    
    // Lire l'image originale
    final bytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) {
      throw Exception('Invalid image format');
    }

    // Redimensionner si nécessaire
    img.Image resized = originalImage;
    if (originalImage.width > _maxWidth || originalImage.height > _maxHeight) {
      resized = img.copyResize(
        originalImage,
        width: originalImage.width > _maxWidth ? _maxWidth : null,
        height: originalImage.height > _maxHeight ? _maxHeight : null,
        maintainAspect: true,
      );
    }

    // Compresser et sauvegarder
    final compressedBytes = img.encodeJpg(resized, quality: _quality);
    final compressedFileName = '${_getFileNameWithoutExtension(fileName)}_compressed.jpg';
    final compressedFile = File('$_compressedPath/$compressedFileName');
    await compressedFile.writeAsBytes(compressedBytes);

    // Créer une vignette
    await _createThumbnail(originalImage, fileName);

    return compressedFileName;
  }

  Future<String> _createThumbnail(img.Image originalImage, String fileName) async {
    final thumbnail = img.copyResize(
      originalImage,
      width: _thumbnailSize,
      height: _thumbnailSize,
      maintainAspect: true,
    );

    final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);
    final thumbnailFileName = '${_getFileNameWithoutExtension(fileName)}_thumb.jpg';
    final thumbnailFile = File('$_thumbnailPath/$thumbnailFileName');
    await thumbnailFile.writeAsBytes(thumbnailBytes);

    return thumbnailFileName;
  }

  String _getFileNameWithoutExtension(String fileName) {
    return fileName.split('.').first;
  }

  File getCompressedFile(String fileName) {
    return File('$_compressedPath/$fileName');
  }

  File getThumbnailFile(String fileName) {
    final thumbName = '${_getFileNameWithoutExtension(fileName)}_thumb.jpg';
    return File('$_thumbnailPath/$thumbName');
  }

  Future<void> deleteImageFiles(String fileName) async {
    final baseName = _getFileNameWithoutExtension(fileName);
    
    // Supprimer tous les formats
    await _deleteIfExists(File('$_originalPath/$fileName'));
    await _deleteIfExists(File('$_compressedPath/${baseName}_compressed.jpg'));
    await _deleteIfExists(File('$_thumbnailPath/${baseName}_thumb.jpg'));
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}