import 'package:flutter/material.dart';
import 'package:shared_models/models/product/product_statistics.dart';
import 'package:shared_models/models/store/store_price.dart';

class ProductStatisticsWidget extends StatelessWidget {
  final ProductStatistics statistics;

  const ProductStatisticsWidget({
    super.key,
    required this.statistics,
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
                  Icons.analytics_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Price Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDateTime(statistics.calculatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Price Statistics Grid
            _buildStatisticsGrid(context),
            const SizedBox(height: 20),

            // Price Distribution
            _buildPriceDistribution(context),
            const SizedBox(height: 20),

            // Best vs Worst Deal
            _buildDealsComparison(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Analysis',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Grid de statistiques 2x3
        Column(
          children: [
            // Première ligne
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Average',
                    '€${statistics.averagePrice.toStringAsFixed(2)}',
                    Icons.trending_flat,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Median',
                    '€${statistics.medianPrice.toStringAsFixed(2)}',
                    Icons.center_focus_strong,
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Deuxième ligne
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Lowest',
                    '€${statistics.minPrice.toStringAsFixed(2)}',
                    Icons.trending_down,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Highest',
                    '€${statistics.maxPrice.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Troisième ligne
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Variance',
                    statistics.priceVariance.toStringAsFixed(3),
                    Icons.scatter_plot,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Std Dev',
                    '€${statistics.standardDeviation.toStringAsFixed(2)}',
                    Icons.show_chart,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDistribution(BuildContext context) {
    // Calculer les buckets de prix pour la distribution
    final priceRange = statistics.maxPrice - statistics.minPrice;
    final bucketSize = priceRange / 5; // 5 buckets
    
    // Compter les prix dans chaque bucket
    final buckets = List.generate(5, (index) => 0);
    for (final storePrice in statistics.allPrices) {
      final price = storePrice.effectivePrice;
      final bucketIndex = ((price - statistics.minPrice) / bucketSize).floor().clamp(0, 4);
      buckets[bucketIndex]++;
    }
    
    final maxCount = buckets.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Distribution',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Histogramme simple
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (index) {
            final count = buckets[index];
            final height = maxCount > 0 ? (count / maxCount * 60).clamp(8.0, 60.0) : 8.0;
            final rangeStart = statistics.minPrice + (index * bucketSize);
            final rangeEnd = rangeStart + bucketSize;
            
            return Column(
              children: [
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '€${rangeStart.toStringAsFixed(1)}-\n€${rangeEnd.toStringAsFixed(1)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDealsComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best vs Worst Deal',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Best Deal
        _buildDealCard(
          context,
          statistics.bestDeal,
          'Best Deal',
          Icons.star,
          Colors.green,
          isPositive: true,
        ),
        const SizedBox(height: 12),
        
        // Worst Deal
        _buildDealCard(
          context,
          statistics.worstDeal,
          'Highest Price',
          Icons.warning,
          Colors.red,
          isPositive: false,
        ),
        const SizedBox(height: 12),
        
        // Savings potential
        if (statistics.bestDeal.effectivePrice != statistics.worstDeal.effectivePrice) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.savings, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Potential Savings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                      Text(
                        'Save €${(statistics.worstDeal.effectivePrice - statistics.bestDeal.effectivePrice).toStringAsFixed(2)} (${(((statistics.worstDeal.effectivePrice - statistics.bestDeal.effectivePrice) / statistics.worstDeal.effectivePrice) * 100).toStringAsFixed(1)}%) by choosing the best deal',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDealCard(
    BuildContext context,
    StorePrice storePrice,
    String title,
    IconData icon,
    Color color, {
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (storePrice.hasActivePromotion) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.local_offer, color: Colors.orange, size: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  storePrice.storeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (storePrice.hasActivePromotion) ...[
                  const SizedBox(height: 2),
                  Text(
                    storePrice.promotion!.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (storePrice.hasActivePromotion && storePrice.price != storePrice.effectivePrice) ...[
                Text(
                  '€${storePrice.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
              ],
              Text(
                '€${storePrice.effectivePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}