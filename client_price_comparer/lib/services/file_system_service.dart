import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileSystemInfo {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime lastModified;
  final bool isDirectory;

  FileSystemInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
    required this.isDirectory,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class StorageSummary {
  final int totalFiles;
  final int totalSizeBytes;
  final int databaseSizeBytes;
  final int imagesSizeBytes;
  final int imagesCount;

  StorageSummary({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.databaseSizeBytes,
    required this.imagesSizeBytes,
    required this.imagesCount,
  });

  String get totalSizeFormatted {
    return _formatBytes(totalSizeBytes);
  }

  String get databaseSizeFormatted {
    return _formatBytes(databaseSizeBytes);
  }

  String get imagesSizeFormatted {
    return _formatBytes(imagesSizeBytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class FileSystemService {
  /// Get storage summary
  static Future<StorageSummary> getStorageSummary() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String productImagesDir = p.join(appDir.path, 'product_images');
    
    int totalFiles = 0;
    int totalSizeBytes = 0;
    int databaseSizeBytes = 0;
    int imagesSizeBytes = 0;
    int imagesCount = 0;

    // Get database size
    final File dbFile = File(p.join(appDir.path, 'app_database.sqlite'));
    if (await dbFile.exists()) {
      databaseSizeBytes = await dbFile.length();
      totalFiles++;
      totalSizeBytes += databaseSizeBytes;
    }

    // Get images directory size
    final Directory imagesDir = Directory(productImagesDir);
    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is File) {
          final int size = await entity.length();
          imagesSizeBytes += size;
          imagesCount++;
          totalFiles++;
          totalSizeBytes += size;
        }
      }
    }

    return StorageSummary(
      totalFiles: totalFiles,
      totalSizeBytes: totalSizeBytes,
      databaseSizeBytes: databaseSizeBytes,
      imagesSizeBytes: imagesSizeBytes,
      imagesCount: imagesCount,
    );
  }

  /// Get list of all files in app directory
  static Future<List<FileSystemInfo>> getAppDirectoryFiles() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final List<FileSystemInfo> files = [];

    await for (final entity in appDir.list(recursive: true)) {
      final stat = await entity.stat();
      files.add(FileSystemInfo(
        path: entity.path,
        name: p.basename(entity.path),
        sizeBytes: entity is File ? await entity.length() : 0,
        lastModified: stat.modified,
        isDirectory: entity is Directory,
      ));
    }

    // Sort by size (largest first)
    files.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return files;
  }

  /// Get list of product images
  static Future<List<FileSystemInfo>> getProductImages() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String productImagesDir = p.join(appDir.path, 'product_images');
    final Directory imagesDir = Directory(productImagesDir);
    final List<FileSystemInfo> images = [];

    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
          final stat = await entity.stat();
          images.add(FileSystemInfo(
            path: entity.path,
            name: p.basename(entity.path),
            sizeBytes: await entity.length(),
            lastModified: stat.modified,
            isDirectory: false,
          ));
        }
      }
    }

    // Sort by modification date (newest first)
    images.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return images;
  }

  /// Delete a specific file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear all product images
  static Future<int> clearAllProductImages() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String productImagesDir = p.join(appDir.path, 'product_images');
    final Directory imagesDir = Directory(productImagesDir);
    int deletedCount = 0;

    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            // Continue with other files
          }
        }
      }
    }

    return deletedCount;
  }

  /// Get app directory path
  static Future<String> getAppDirectoryPath() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }
}