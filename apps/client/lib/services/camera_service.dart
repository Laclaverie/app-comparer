import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription> _cameras = [];

  /// Check camera permission
  static Future<bool> checkCameraPermission() async {
    final PermissionStatus status = await Permission.camera.status;
    
    if (status.isDenied) {
      final PermissionStatus result = await Permission.camera.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }

  /// Initialize cameras with permission check
  static Future<bool> initialize() async {
    try {
      // Check permission first
      final bool hasPermission = await checkCameraPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Camera permission denied');
        }
        return false;
      }
      
      _cameras = await availableCameras();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing cameras: $e');
      }
      _cameras = [];
      return false;
    }
  }

  /// Get camera controller with lower resolution
  static Future<CameraController?> getCameraController() async {
    if (_cameras.isEmpty) {
      final bool initialized = await initialize();
      if (!initialized) {
        return null;
      }
    }
    
    if (_cameras.isEmpty) return null;

    try {
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium, // Changed from high to medium
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // Add this for better performance
      );

      await _controller!.initialize();
      return _controller;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating camera controller: $e');
      }
      return null;
    }
  }

  /// Take a picture and save it with low resolution
  static Future<String?> takePictureAndSave(String barcode) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      // Take the picture
      final XFile picture = await _controller!.takePicture();
      
      // Get app's internal directory (not accessible from gallery)
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String productImagesDir = p.join(appDir.path, 'product_images');
      
      // Create directory if it doesn't exist
      final Directory dir = Directory(productImagesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'product_${barcode}_$timestamp.jpg';
      final String filePath = p.join(productImagesDir, fileName);

      // Read and resize the image
      final Uint8List imageBytes = await picture.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        // Clean up on failure
        await File(picture.path).delete();
        return null;
      }

      // Resize to low resolution (max 800px width, maintaining aspect ratio)
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: originalImage.width > 800 ? 800 : originalImage.width,
      );

      // Save the resized image
      final File savedFile = File(filePath);
      await savedFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 70));

      // Clean up immediately after processing
      await File(picture.path).delete();
      
      // DON'T dispose camera here - let the scan page manage it
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error taking picture: $e');
      }
      return null;
    }
  }

  /// Dispose camera controller
  static Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}