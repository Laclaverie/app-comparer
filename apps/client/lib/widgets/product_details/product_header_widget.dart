import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

class ProductHeaderWidget extends StatelessWidget {
  final ProductDto product;
  final bool fromNotification;

  const ProductHeaderWidget({
    super.key,
    required this.product,
    this.fromNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec badge si vient d'une notification
            if (fromNotification) ...[
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'From price alert',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Nom du produit
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Informations de base
            Row(
              children: [
                // Code-barres
                ...[
                Icon(
                  Icons.qr_code,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Code: ${product.barcode}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              ],
            ),
            
            // Description si disponible
            if (product.description != null && product.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                product.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Image si disponible
            if (product.imageUrl != null || product.localImagePath != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl ?? '',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback vers image locale si disponible
                    if (product.localImagePath != null) {
                      return Image.asset(
                        product.localImagePath!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 48,
                            ),
                          );
                        },
                      );
                    }
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}