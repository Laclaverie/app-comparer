import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

class ProductDescriptionSection extends StatelessWidget {
  final ProductDto product;

  const ProductDescriptionSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    if (product.description == null || product.description!.trim().isEmpty) {
      return _buildNoDescriptionWidget(context);
    }

    return _buildDescriptionWidget(context);
  }

  Widget _buildNoDescriptionWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aucune description disponible',
              style: TextStyle(
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _onAddDescriptionPressed(context),
            child: Text(
              'Ajouter',
              style: TextStyle(color: Colors.orange[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionHeader(context),
          const SizedBox(height: 8),
          _buildDescriptionContent(context),
        ],
      ),
    );
  }

  Widget _buildDescriptionHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.description, color: Colors.blue[700], size: 20),
        const SizedBox(width: 8),
        Text(
          'Description',
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _onEditDescriptionPressed(context),
          icon: Icon(Icons.edit, color: Colors.blue[700], size: 16),
          tooltip: 'Modifier la description',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDescriptionContent(BuildContext context) {
    return Text(
      product.description!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.4,
      ),
    );
  }

  void _onAddDescriptionPressed(BuildContext context) {
    // ✅ TODO : Implémentation ajout description
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout description - À implémenter')),
    );
  }

  void _onEditDescriptionPressed(BuildContext context) {
    // ✅ TODO : Implémentation édition description
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Édition description - À implémenter')),
    );
  }
}