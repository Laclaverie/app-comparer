import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';
import 'shared/product_ui_helpers.dart';

class ProductMetadataGrid extends StatelessWidget {
  final ProductDto product;

  const ProductMetadataGrid({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _buildMetadataRows(context),
      ),
    );
  }

  List<Widget> _buildMetadataRows(BuildContext context) {
    final rows = <Widget>[];

    if (product.id != null) {
      rows.add(_buildMetadataRow(
        context, 
        Icons.tag, 
        'Product ID', 
        '#${product.id}',
      ));
    }

    if (product.brandId != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_buildMetadataRow(
        context, 
        Icons.branding_watermark, 
        'Brand', 
        'ID #${product.brandId}',
      ));
    }

    if (product.categoryId != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_buildMetadataRow(
        context, 
        Icons.category, 
        'Category', 
        'ID #${product.categoryId}',
      ));
    }

    if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
    rows.add(_buildMetadataRow(
      context, 
      Icons.access_time, 
      'Added', 
      ProductUIHelpers.formatDate(product.createdAt),
    ));

    if (product.updatedAt != null && product.updatedAt != product.createdAt) {
      rows.add(const SizedBox(height: 8));
      rows.add(_buildMetadataRow(
        context, 
        Icons.update, 
        'Updated', 
        ProductUIHelpers.formatDate(product.updatedAt),
      ));
    }

    return rows;
  }

  Widget _buildMetadataRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}