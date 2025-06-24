import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

class ProductInfoCard extends StatelessWidget {
  final ProductDto product;

  const ProductInfoCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            if (product.description != null) ...[
              Text(
                product.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            
            // Code-barres
            _buildBarcodeChip(context),
            
            const SizedBox(height: 16),
            
            // Image
            _buildProductImage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code, size: 16),
          const SizedBox(width: 8),
          Text(
            'Code: ${product.barcode}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    if (product.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          product.imageUrl!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildImagePlaceholder(context, isLoading: true);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(context, hasError: true);
          },
        ),
      );
    }
    
    return _buildImagePlaceholder(context);
  }

  Widget _buildImagePlaceholder(BuildContext context, {bool isLoading = false, bool hasError = false}) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Loading image...'),
            ] else if (hasError) ...[
              const Icon(Icons.image_not_supported, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              const Text('Image not available', style: TextStyle(color: Colors.red)),
            ] else ...[
              const Icon(Icons.photo, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('No image available', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}