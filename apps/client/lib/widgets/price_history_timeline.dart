import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'shared/price_formatting_helpers.dart';

class PriceHistoryTimeline extends StatelessWidget {
  final List<PriceHistoryDto> priceHistory;
  final bool isAdvancedMode;

  const PriceHistoryTimeline({
    super.key,
    required this.priceHistory,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return _buildEmptyTimeline(context);
    }

    // Grouper par date pour une meilleure lisibilité
    final groupedHistory = _groupByDate(priceHistory);

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineHeader(context),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: groupedHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = groupedHistory.entries.elementAt(index);
                final date = entry.key;
                final prices = entry.value;
                
                return _TimelineDayGroup(
                  date: date,
                  prices: prices,
                  isAdvancedMode: isAdvancedMode,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Aucun historique disponible',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineHeader(BuildContext context) {
    final totalEntries = priceHistory.length;
    final uniqueStores = priceHistory.map((p) => p.storeName).toSet().length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline des prix',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalEntries entrées • $uniqueStores magasins',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<PriceHistoryDto>> _groupByDate(List<PriceHistoryDto> history) {
    final Map<DateTime, List<PriceHistoryDto>> grouped = {};
    
    for (final price in history) {
      // Grouper par jour (ignorer heure/minute)
      final dateKey = DateTime(price.date.year, price.date.month, price.date.day);
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(price);
    }
    
    // Trier chaque groupe par prix croissant
    for (final prices in grouped.values) {
      prices.sort((a, b) => a.price.compareTo(b.price));
    }
    
    return grouped;
  }
}

class _TimelineDayGroup extends StatelessWidget {
  final DateTime date;
  final List<PriceHistoryDto> prices;
  final bool isAdvancedMode;

  const _TimelineDayGroup({
    required this.date,
    required this.prices,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    final lowestPrice = prices.first;
    final highestPrice = prices.last;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context),
          const Divider(height: 1),
          ...prices.asMap().entries.map((entry) {
            final index = entry.key;
            final price = entry.value;
            final isLowest = price == lowestPrice;
            final isHighest = price == highestPrice && prices.length > 1;
            
            return _TimelinePriceItem(
              price: price,
              isLowest: isLowest,
              isHighest: isHighest,
              isAdvancedMode: isAdvancedMode,
              isLast: index == prices.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    
    String dateText;
    if (isToday) {
      dateText = 'Aujourd\'hui';
    } else if (isYesterday) {
      dateText = 'Hier';
    } else {
      dateText = _formatDate(date);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: isToday ? Colors.green[600] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            dateText,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.green[700] : Colors.grey[700],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${prices.length} prix',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _TimelinePriceItem extends StatelessWidget {
  final PriceHistoryDto price;
  final bool isLowest;
  final bool isHighest;
  final bool isAdvancedMode;
  final bool isLast;

  const _TimelinePriceItem({
    required this.price,
    required this.isLowest,
    required this.isHighest,
    required this.isAdvancedMode,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: isLast ? null : Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Row(
        children: [
          _buildTimelineIndicator(),
          const SizedBox(width: 12),
          _buildStoreInfo(context),
          const Spacer(),
          _buildPriceInfo(context),
          if (isAdvancedMode) ...[
            const SizedBox(width: 8),
            _buildDetailsButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getIndicatorColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStoreInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  price.storeName ?? 'Magasin #${price.supermarketId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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
          if (isAdvancedMode && price.storeLocation != null) ...[
            const SizedBox(height: 2),
            Text(
              price.storeLocation!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBestPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'BEST',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isLowest ? Colors.green[700] : null,
          ),
        ),
        if (price.isPromotion && price.originalPrice != null) ...[
          Text(
            PriceFormattingHelpers.formatPrice(price.originalPrice!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[500],
            ),
          ),
        ],
        if (isAdvancedMode) ...[
          Text(
            PriceFormattingHelpers.formatTimeAgo(price.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, size: 16),
      onPressed: () => _showPriceDetails(context),
      tooltip: 'Détails',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Color? _getBackgroundColor() {
    if (isLowest) return Colors.green[25];
    if (isHighest) return Colors.red[25];
    return null;
  }

  Color _getIndicatorColor() {
    if (isLowest) return Colors.green;
    if (isHighest) return Colors.red;
    return Colors.blue;
  }

  void _showPriceDetails(BuildContext context) {
    // ✅ TODO : Afficher détails du prix
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails prix ${price.storeName} - À implémenter')),
    );
  }
}