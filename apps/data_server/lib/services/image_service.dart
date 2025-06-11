import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'compression_service.dart';

class ImageService {
  final CompressionService _compressionService = CompressionService();

  Future<String> saveAndCompressImage(Uint8List imageBytes, String originalFileName) async {
    // Générer un nom unique
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFileName.split('.').last;
    final uniqueFileName = '${timestamp}_$originalFileName';

    // Sauvegarder l'original
    final originalFile = File('assets/images/original/$uniqueFileName');
    await originalFile.writeAsBytes(imageBytes);

    // Compresser
    final compressedFileName = await _compressionService.compressImage(
      originalFile, 
      uniqueFileName,
    );

    return compressedFileName;
  }

  Response getCompressedImage(String fileName) {
    try {
      final file = _compressionService.getCompressedFile(fileName);
      
      if (!file.existsSync()) {
        return Response.notFound('Image not found');
      }

      final bytes = file.readAsBytesSync();
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': bytes.length.toString(),
          'Cache-Control': 'public, max-age=31536000', // Cache 1 an
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: 'Error serving image: $e',
      );
    }
  }

  Response getThumbnail(String fileName) {
    try {
      final file = _compressionService.getThumbnailFile(fileName);
      
      if (!file.existsSync()) {
        return Response.notFound('Thumbnail not found');
      }

      final bytes = file.readAsBytesSync();
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': bytes.length.toString(),
          'Cache-Control': 'public, max-age=31536000',
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: 'Error serving thumbnail: $e',
      );
    }
  }

  Future<void> deleteImage(String fileName) async {
    await _compressionService.deleteImageFiles(fileName);
  }
}