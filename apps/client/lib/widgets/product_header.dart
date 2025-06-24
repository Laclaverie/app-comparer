import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

class ProductHeader extends StatelessWidget {
  final ProductDto product;

  const ProductHeader({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildBarcodeChip(context),
            ],
          ),
        ),
        _ProductActionButtons(product: product),
      ],
    );
  }

  Widget _buildBarcodeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            '${product.barcode}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductActionButtons extends StatelessWidget {
  final ProductDto product;

  const _ProductActionButtons({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () => _onFavoritePressed(context),
          tooltip: 'Add to favorites',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _onSharePressed(context),
          tooltip: 'Share product',
        ),
      ],
    );
  }

  void _onFavoritePressed(BuildContext context) {
    // ✅ TODO : Implémentation favoris
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favoris - À implémenter')),
    );
  }

  void _onSharePressed(BuildContext context) {
    // ✅ TODO : Implémentation partage  
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage - À implémenter')),
    );
  }
}