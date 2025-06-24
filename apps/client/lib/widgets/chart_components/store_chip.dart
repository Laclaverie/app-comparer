import 'package:client_price_comparer/services/charts/store_comparison_service.dart';
import 'package:flutter/material.dart';

class StoreChip extends StatelessWidget {
  final StoreChartData storeData;
  final bool isVisible;
  final bool isBestPrice;
  final bool isCompactMode;
  final Function(bool) onToggled;

  const StoreChip({
    super.key,
    required this.storeData,
    required this.isVisible,
    required this.isBestPrice,
    required this.isCompactMode,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final latestPrice = StoreComparisonService.getLatestPrice(storeData);
    
    return SizedBox(
      width: double.infinity,
      child: FilterChip(
        label: _buildChipContent(latestPrice),
        selected: isVisible,
        onSelected: onToggled,
        selectedColor: isBestPrice 
            ? Colors.amber.withValues(alpha: 0.3)
            : storeData.color.withValues(alpha: 0.2),
        checkmarkColor: isBestPrice ? Colors.amber.shade700 : storeData.color,
        side: BorderSide(
          color: isBestPrice 
              ? Colors.amber.shade600
              : storeData.color.withValues(alpha: 0.5),
          width: isBestPrice ? 2 : 1,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: EdgeInsets.symmetric(
          horizontal: isCompactMode ? 6 : 8,
          vertical: isCompactMode ? 2 : 4,
        ),
      ),
    );
  }

  Widget _buildChipContent(double? latestPrice) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColorIndicator(),
        SizedBox(width: isCompactMode ? 6 : 8),
        _buildStoreNameSection(),
        if (storeData.prices.isNotEmpty) ...[
          const SizedBox(width: 8),
          _buildPriceSection(latestPrice),
        ],
        if (!isCompactMode && storeData.prices.isNotEmpty) ...[
          const SizedBox(width: 6),
          _buildQualityIndicator(),
        ],
      ],
    );
  }

  /// ✅ Indicateur de couleur avec couronne pour les champions
  Widget _buildColorIndicator() {
    return Stack(
      children: [
        Container(
          width: isCompactMode ? 12 : 14,
          height: isCompactMode ? 12 : 14,
          decoration: BoxDecoration(
            color: storeData.color,
            shape: BoxShape.circle,
            // ✅ Bordure dorée pour les champions
            border: isBestPrice ? Border.all(
              color: Colors.amber.shade600,
              width: 2,
            ) : null,
          ),
        ),
        // ✅ Étoile pour les champions
        if (isBestPrice)
          Positioned(
            top: -3,
            right: -3,
            child: Icon(
              Icons.star,
              size: 10,
              color: Colors.amber.shade600,
            ),
          ),
      ],
    );
  }

  /// ✅ Section nom du magasin avec icône champion
  Widget _buildStoreNameSection() {
    return Expanded(
      child: Row(
        children: [
          // ✅ Icône trophée pour les champions
          if (isBestPrice) ...[
            Icon(
              Icons.emoji_events,
              size: isCompactMode ? 12 : 14,
              color: Colors.amber.shade600,
            ),
            const SizedBox(width: 4),
          ],
          // ✅ Nom du magasin
          Expanded(
            child: Text(
              storeData.storeName,
              style: TextStyle(
                fontSize: isCompactMode ? 12 : 13,
                fontWeight: isBestPrice ? FontWeight.w700 : FontWeight.w500,
                color: isBestPrice ? Colors.amber.shade800 : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Section prix avec compteur et badge champion
  Widget _buildPriceSection(double? latestPrice) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ✅ Badge "BEST" pour les champions (en mode avancé)
        if (isBestPrice && !isCompactMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'BEST',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
        
        // ✅ Compteur de prix
        Text(
          '(${storeData.prices.length})',
          style: TextStyle(
            fontSize: isCompactMode ? 9 : 10,
            color: Colors.grey.shade600,
          ),
        ),
        
        // ✅ Prix le plus récent (en mode avancé)
        if (!isCompactMode && latestPrice != null) ...[
          const SizedBox(height: 1),
          Text(
            '${latestPrice.toStringAsFixed(2)}€',
            style: TextStyle(
              fontSize: 9,
              fontWeight: isBestPrice ? FontWeight.bold : FontWeight.normal,
              color: isBestPrice ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  /// ✅ Indicateur de qualité des données
  Widget _buildQualityIndicator() {
    final dataCount = storeData.prices.length;
    Color indicatorColor;
    String tooltip;
    
    if (dataCount >= 10) {
      indicatorColor = Colors.green;
      tooltip = 'Excellent ($dataCount prix)';
    } else if (dataCount >= 5) {
      indicatorColor = Colors.orange;
      tooltip = 'Bon ($dataCount prix)';
    } else if (dataCount >= 2) {
      indicatorColor = Colors.red;
      tooltip = 'Limité ($dataCount prix)';
    } else {
      indicatorColor = Colors.grey;
      tooltip = 'Très limité ($dataCount prix)';
    }
    
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: indicatorColor,
          shape: BoxShape.circle,
          // ✅ Petit effet de brillance pour les champions
          boxShadow: isBestPrice ? [
            BoxShadow(
              color: Colors.amber.shade300,
              blurRadius: 2,
              spreadRadius: 0.5,
            ),
          ] : null,
        ),
      ),
    );
  }
}