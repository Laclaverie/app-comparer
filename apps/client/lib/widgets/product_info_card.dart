import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';
import 'product_description_section.dart';
import 'product_header.dart';
import 'product_image_display.dart';
import 'product_metadata_grid.dart';

class ProductInfoCard extends StatelessWidget {
  final ProductDto product;
  
  const ProductInfoCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Header avec titre et favoris
            ProductHeader(product: product),
            const SizedBox(height: 16),
            
            // ✅ Métadonnées enrichies
            ProductMetadataGrid(product: product),
            const SizedBox(height: 16),
            
            // ✅ Description
            ProductDescriptionSection(product: product),
            const SizedBox(height: 16),
            
            // ✅ Image avec gestion d'erreurs améliorée
            ProductImageDisplay(product: product),
          ],
        ),
      ),
    );
  }
}