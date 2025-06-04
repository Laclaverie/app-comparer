import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:client_price_comparer/services/file_system_service.dart';

class FileSystemDebugPage extends StatefulWidget {
  const FileSystemDebugPage({super.key});

  @override
  State<FileSystemDebugPage> createState() => _FileSystemDebugPageState();
}

class _FileSystemDebugPageState extends State<FileSystemDebugPage> {
  StorageSummary? _storageSummary;
  List<FileSystemInfo> _allFiles = [];
  List<FileSystemInfo> _productImages = [];
  bool _isLoading = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFileSystemInfo();
  }

  Future<void> _loadFileSystemInfo() async {
    setState(() => _isLoading = true);

    try {
      final summary = await FileSystemService.getStorageSummary();
      final allFiles = await FileSystemService.getAppDirectoryFiles();
      final images = await FileSystemService.getProductImages();

      if (mounted) {
        setState(() {
          _storageSummary = summary;
          _allFiles = allFiles;
          _productImages = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load file system info: $e');
      }
    }
  }

  Future<void> _clearAllImages() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Images'),
        content: const Text('Are you sure you want to delete all product images? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final int deletedCount = await FileSystemService.clearAllProductImages();
        _showSuccess('Deleted $deletedCount images');
        _loadFileSystemInfo(); // Refresh
      } catch (e) {
        _showError('Failed to clear images: $e');
      }
    }
  }

  Future<void> _copyPathToClipboard(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    _showSuccess('Path copied to clipboard');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File System Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFileSystemInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Storage Summary Card
                if (_storageSummary != null) _buildStorageSummary(),
                
                // Tabs
                Container(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _selectedTabIndex = 0),
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedTabIndex == 0 
                                ? Theme.of(context).primaryColor.withOpacity(0.2)
                                : null,
                          ),
                          child: const Text('All Files'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _selectedTabIndex = 1),
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedTabIndex == 1 
                                ? Theme.of(context).primaryColor.withOpacity(0.2)
                                : null,
                          ),
                          child: const Text('Product Images'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // File Lists
                Expanded(
                  child: _selectedTabIndex == 0 
                      ? _buildAllFilesList()
                      : _buildProductImagesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageSummary() {
    final summary = _storageSummary!;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Total Size', summary.totalSizeFormatted),
            _buildSummaryRow('Database Size', summary.databaseSizeFormatted),
            _buildSummaryRow('Images Size', summary.imagesSizeFormatted),
            _buildSummaryRow('Total Files', '${summary.totalFiles}'),
            _buildSummaryRow('Images Count', '${summary.imagesCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFilesList() {
    return ListView.builder(
      itemCount: _allFiles.length,
      itemBuilder: (context, index) {
        final file = _allFiles[index];
        return ListTile(
          leading: Icon(
            file.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: file.isDirectory ? Colors.blue : Colors.grey,
          ),
          title: Text(file.name),
          subtitle: Text(
            '${file.sizeFormatted} • ${file.lastModified.toString().split('.')[0]}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyPathToClipboard(file.path),
          ),
        );
      },
    );
  }

  Widget _buildProductImagesList() {
    return Column(
      children: [
        // Clear all button
        if (_productImages.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _clearAllImages,
              icon: const Icon(Icons.delete_sweep),
              label: Text('Clear All Images (${_productImages.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        
        // Images list
        Expanded(
          child: _productImages.isEmpty
              ? const Center(
                  child: Text('No product images found'),
                )
              : ListView.builder(
                  itemCount: _productImages.length,
                  itemBuilder: (context, index) {
                    final image = _productImages[index];
                    return ListTile(
                      leading: const Icon(Icons.image, color: Colors.green),
                      title: Text(image.name),
                      subtitle: Text(
                        '${image.sizeFormatted} • ${image.lastModified.toString().split('.')[0]}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyPathToClipboard(image.path),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteImage(image),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _deleteImage(FileSystemInfo image) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: Text('Delete ${image.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await FileSystemService.deleteFile(image.path);
      if (success) {
        _showSuccess('Image deleted');
        _loadFileSystemInfo(); // Refresh
      } else {
        _showError('Failed to delete image');
      }
    }
  }
}