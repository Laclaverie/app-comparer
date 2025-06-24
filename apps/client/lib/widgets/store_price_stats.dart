// lib/widgets/store_price_stats.dart
import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'shared/price_formatting_helpers.dart';

class StorePriceStats extends StatelessWidget {
  final List<PriceHistoryDto> prices;

  const StorePriceStats({
    super.key,
    required this.prices,
  });

  @override
  Widget build(BuildContext context) {
    final stats = PriceFormattingHelpers.calculatePriceStats(prices);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatsHeader(context),
          const SizedBox(height: 12),
          _buildStatsGrid(context, stats),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.analytics, color: Colors.blue[700], size: 20),
        const SizedBox(width: 8),
        Text(
          'Analyse des prix',
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, PriceStatistics stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Le moins cher',
                PriceFormattingHelpers.formatPrice(stats.lowest),
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Le plus cher',
                PriceFormattingHelpers.formatPrice(stats.highest),
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Moyenne',
                PriceFormattingHelpers.formatPrice(stats.average),
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Écart',
                PriceFormattingHelpers.formatPercentage(stats.differencePercent),
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}