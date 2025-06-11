import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/image_service.dart';

class ImageHandlers {
  final ImageService imageService;

  ImageHandlers(this.imageService);

  Future<Response> uploadImage(Request request) async {
    try {
      final contentType = request.headers['content-type'];
      if (contentType == null || !contentType.startsWith('multipart/form-data')) {
        return Response.badRequest(
          body: json.encode({'error': 'Content-Type must be multipart/form-data'}),
        );
      }

      // Note: Vous devrez implémenter le parsing multipart
      // ou utiliser une librairie comme 'mime' pour parser les uploads
      
      // Pour l'instant, exemple simplifié avec bytes directs
      final bytes = await request.read().expand((chunk) => chunk).toList();
      final imageBytes = Uint8List.fromList(bytes);
      
      final fileName = request.headers['x-filename'] ?? 'image.jpg';
      final compressedFileName = await imageService.saveAndCompressImage(
        imageBytes, 
        fileName,
      );

      return Response.ok(
        json.encode({
          'fileName': compressedFileName,
          'imageUrl': '/api/images/compressed/$compressedFileName',
          'thumbnailUrl': '/api/images/thumbnails/$compressedFileName',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to upload image: $e'}),
      );
    }
  }

  Future<Response> getCompressedImage(Request request) async {
    final fileName = request.params['filename'];
    if (fileName == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Filename is required'}),
      );
    }

    return imageService.getCompressedImage(fileName);
  }

  Future<Response> getThumbnail(Request request) async {
    final fileName = request.params['filename'];
    if (fileName == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Filename is required'}),
      );
    }

    return imageService.getThumbnail(fileName);
  }
}