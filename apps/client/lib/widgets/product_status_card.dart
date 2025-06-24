import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

enum ProductDisplayModeTmp { minimal, advanced }

class ProductStatusCard extends StatelessWidget {
  final ProductDto product;
  final ProductDisplayModeTmp currentMode;

  const ProductStatusCard({
    super.key,
    required this.product,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Product Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status actif/inactif
            _buildStatusRow(
              context,
              icon: product.isActive ? Icons.check_circle : Icons.cancel,
              color: product.isActive ? Colors.green : Colors.red,
              label: product.isActive ? 'Active' : 'Inactive',
            ),
            
            const SizedBox(height: 12),
            
            // Mode d'affichage
            _buildStatusRow(
              context,
              icon: currentMode == ProductDisplayModeTmp.minimal 
                  ? Icons.visibility 
                  : Icons.analytics,
              color: Colors.blue,
              label: 'Display Mode: ${currentMode == ProductDisplayModeTmp.minimal ? 'Minimal' : 'Advanced'}',
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Métadonnées
            _buildMetadataRows(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRows(BuildContext context) {
    return Column(
      children: [
        if (product.id != null) 
          _buildInfoRow(context, Icons.tag, 'Product ID', '#${product.id}'),
        
        if (product.brandId != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.branding_watermark, 'Brand ID', '#${product.brandId}'),
        ],
        
        if (product.categoryId != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.category, 'Category ID', '#${product.categoryId}'),
        ],
        
        const SizedBox(height: 8),
        _buildInfoRow(context, Icons.schedule, 'Added', _formatDate(product.createdAt)),
        
        if (product.updatedAt != null && product.updatedAt != product.createdAt) ...[
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.update, 'Last Updated', _formatDate(product.updatedAt)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}