import 'package:flutter/material.dart';
import 'package:client_price_comparer/models/store/store_price.dart';

class UnitPriceDisplayWidget extends StatelessWidget {
  final StorePrice storePrice;
  final bool isHighlighted;

  const UnitPriceDisplayWidget({
    super.key,
    required this.storePrice,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPromotion = storePrice.promotion != null && storePrice.promotion!.isValid;
    final regularPrice = storePrice.price;
    final effectivePrice = storePrice.effectivePrice;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? Colors.green[300]! : Colors.grey[300]!,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name with badge
          Row(
            children: [
              Icon(
                storePrice.isCurrentStore ? Icons.star : Icons.store,
                color: storePrice.isCurrentStore ? Colors.amber : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  storePrice.storeName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isHighlighted ? Colors.green[700] : Colors.black87,
                  ),
                ),
              ),
              if (isHighlighted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BEST DEAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Regular unit price
          Row(
            children: [
              const Text(
                'Regular price per unit:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                '€${regularPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: hasPromotion ? TextDecoration.lineThrough : null,
                  color: hasPromotion ? Colors.grey : Colors.black87,
                ),
              ),
            ],
          ),
          
          // Effective unit price (if different from regular)
          if (hasPromotion) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Effective price per unit:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '€${effectivePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.green[700] : Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Promotion badge and explanation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer, color: Colors.orange[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        storePrice.promotion!.description,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    storePrice.promotion!.getDetailedExplanation(regularPrice),
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            // Savings display
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Save €${(regularPrice - effectivePrice).toStringAsFixed(2)} (${storePrice.promotion!.getSavingsPercentage(regularPrice).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Last updated
          Text(
            'Updated: ${_formatDateTime(storePrice.lastUpdated)}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}