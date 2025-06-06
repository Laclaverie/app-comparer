import 'dart:io';
import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';

class ProductHeaderWidget extends StatelessWidget {
  final Product product;
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
        child: Row(
          children: [
            // Product Image
            _buildProductImage(),
            const SizedBox(width: 16),
            
            // Product Info
            Expanded(child: _buildProductInfo(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        image: product.imageUrl != null 
            ? DecorationImage(
                image: FileImage(File(product.imageUrl!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: product.imageUrl == null 
          ? const Icon(Icons.shopping_basket, size: 40, color: Colors.grey)
          : null,
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Barcode: ${product.barcode}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (fromNotification) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'From notification',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}