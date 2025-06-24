import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

class ProductImageDisplay extends StatefulWidget {
  final ProductDto product;

  const ProductImageDisplay({
    super.key,
    required this.product,
  });

  @override
  State<ProductImageDisplay> createState() => _ProductImageDisplayState();
}

class _ProductImageDisplayState extends State<ProductImageDisplay> {
  bool _hasImageError = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _buildContainerDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageContent(),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.2),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (widget.product.imageUrl != null && !_hasImageError) {
      return _buildNetworkImage();
    }
    return _buildImagePlaceholder();
  }

  Widget _buildNetworkImage() {
    return GestureDetector(
      onTap: () => _onImageTapped(context),
      child: Image.network(
        widget.product.imageUrl!,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: _buildLoadingWidget,
        errorBuilder: _buildErrorWidget,
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    
    return Container(
      height: 250,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement de l\'image...',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (loadingProgress.expectedTotalBytes != null)
              _buildProgressText(loadingProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressText(ImageChunkEvent loadingProgress) {
    final loaded = (loadingProgress.cumulativeBytesLoaded / 1024).round();
    final total = (loadingProgress.expectedTotalBytes! / 1024).round();
    
    return Text(
      '$loaded / $total KB',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 12,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _hasImageError = true);
    });

    return _buildImageError();
  }

  Widget _buildImageError() {
    return Container(
      height: 250,
      color: Colors.red[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger l\'image',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _onRetryImage,
                  child: Text(
                    'Réessayer',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => _onChangeImagePressed(context),
                  child: Text(
                    'Changer',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune image disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'image apparaîtra ici une fois ajoutée',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _onAddImagePressed(context),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Ajouter une image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onImageTapped(BuildContext context) {
    // ✅ TODO : Agrandir l'image en plein écran
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agrandissement image - À implémenter')),
    );
  }

  void _onRetryImage() {
    setState(() {
      _hasImageError = false;
    });
  }

  void _onAddImagePressed(BuildContext context) {
    // ✅ TODO : Ajouter une image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout image - À implémenter')),
    );
  }

  void _onChangeImagePressed(BuildContext context) {
    // ✅ TODO : Changer l'image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changement image - À implémenter')),
    );
  }
}