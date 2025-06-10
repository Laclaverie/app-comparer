import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:client_price_comparer/services/camera_service.dart';

class CameraCaptureePage extends StatefulWidget {
  final String barcode;
  
  const CameraCaptureePage({super.key, required this.barcode});

  @override
  State<CameraCaptureePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCaptureePage> {
  CameraController? _controller;
  bool _isLoading = true;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = await CameraService.getCameraController();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || _isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final String? filePath = await CameraService.takePictureAndSave(widget.barcode);
      
      if (filePath != null && mounted) {
        // Return the file path to the registration page
        Navigator.pop(context, filePath);
      } else {
        _showError('Failed to save picture');
        setState(() => _isTakingPicture = false);
      }
    } catch (e) {
      _showError('Error taking picture: $e');
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
    // Note: Don't reset _isTakingPicture to false here if navigation succeeded
    // because the page will be disposed anyway
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Take Product Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller == null
              ? const Center(
                  child: Text(
                    'Camera not available',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Stack(
                  children: [
                    // Camera preview
                    Positioned.fill(
                      child: CameraPreview(_controller!),
                    ),
                    
                    // Instructions
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Position the product in the frame and tap the capture button',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    // Capture button
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _isTakingPicture ? null : _takePicture,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isTakingPicture ? Colors.grey : Colors.white,
                              border: Border.all(color: Colors.grey, width: 3),
                            ),
                            child: _isTakingPicture
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.black,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    // Ensure camera is disposed when leaving the page
    CameraService.dispose();
    super.dispose();
  }
}