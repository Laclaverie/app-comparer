// lib/widgets/store_price_item.dart
import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'shared/price_formatting_helpers.dart';

class StorePriceItem extends StatelessWidget {
  final PriceHistoryDto price;
  final bool isLowest;
  final bool isHighest;
  final bool isAdvancedMode;

  const StorePriceItem({
    super.key,
    required this.price,
    required this.isLowest,
    required this.isHighest,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(),
          width: isLowest ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildStoreIcon(),
          const SizedBox(width: 12),
          Expanded(child: _buildStoreInfo(context)),
          _buildPriceInfo(context),
          if (isAdvancedMode) ...[
            const SizedBox(width: 8),
            _buildActionButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isLowest ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.store,
        color: isLowest ? Colors.green[700] : Colors.grey[600],
      ),
    );
  }

  Widget _buildStoreInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                price.storeName ?? 'Magasin #${price.supermarketId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLowest) ...[
              const SizedBox(width: 8),
              _buildBestPriceBadge(),
            ],
          ],
        ),
        if (isAdvancedMode) ...[
          const SizedBox(height: 4),
          Text(
            'Mis à jour ${PriceFormattingHelpers.formatTimeAgo(price.date)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBestPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'MEILLEUR PRIX',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          PriceFormattingHelpers.formatPrice(price.price),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isLowest ? Colors.green[700] : null,
          ),
        ),
        if (price.originalPrice != null && price.originalPrice! > price.price) ...[
          const SizedBox(height: 2),
          Text(
            PriceFormattingHelpers.formatPrice(price.originalPrice!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showPriceOptions(context),
      tooltip: 'Options',
    );
  }

  Color _getBackgroundColor() {
    if (isLowest) return Colors.green[50]!;
    if (isHighest) return Colors.red[50]!;
    return Colors.grey[50]!;
  }

  Color _getBorderColor() {
    if (isLowest) return Colors.green[200]!;
    if (isHighest) return Colors.red[200]!;
    return Colors.grey[200]!;
  }

  void _showPriceOptions(BuildContext context) {
    // ✅ TODO : Options (signaler erreur, historique, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Options prix - À implémenter')),
    );
  }
}