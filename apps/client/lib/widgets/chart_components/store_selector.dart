import 'package:flutter/material.dart';
import '../../services/charts/store_comparison_service.dart';

class StoreSelector extends StatefulWidget {
  final Map<int, StoreChartData> storeData;
  final Function(int storeId, bool isVisible) onStoreToggled;
  final bool isAdvancedMode;

  const StoreSelector({
    super.key,
    required this.storeData,
    required this.onStoreToggled,
    required this.isAdvancedMode,
  });

  @override
  State<StoreSelector> createState() => _StoreSelectorState();
}

class _StoreSelectorState extends State<StoreSelector> {
  Map<int, bool> _localStoreVisibility = {};
  int? _bestPriceStoreId;

  @override
  void initState() {
    super.initState();
    _forceSmartInitialization(); // ✅ Force la sélection intelligente
  }

  @override
  void didUpdateWidget(StoreSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeData != widget.storeData) {
      _updateLocalVisibility();
    }
  }

  void _updateLocalVisibility() {
    // ✅ Identifier le champion AVANT tout
    _bestPriceStoreId = StoreComparisonService.findBestPriceStoreId(widget.storeData);
    
    // ✅ DEBUG : Vérifier les données
    print('🏪 Magasins disponibles: ${widget.storeData.keys.toList()}');
    print('🏆 Champion identifié: $_bestPriceStoreId');
    
    // ✅ Vérifier la sélection existante
    final visibleStores = widget.storeData.values.where((store) => store.isVisible).toList();
    final hasExistingSelection = visibleStores.isNotEmpty;
    
    print('📊 Magasins actuellement visibles: ${visibleStores.map((s) => '${s.storeId}:${s.storeName}').toList()}');
    print('🔍 A une sélection existante: $hasExistingSelection');
    
    if (hasExistingSelection) {
      // ✅ Garder la sélection existante
      print('✅ Conservation de la sélection existante');
      _localStoreVisibility = Map.fromEntries(
        widget.storeData.entries.map((entry) {
          return MapEntry(entry.key, entry.value.isVisible);
        }),
      );
    } else {
      // ✅ Appliquer la sélection intelligente
      print('🎯 Application de la sélection intelligente...');
      
      final smartSelection = StoreComparisonService.calculateSmartDefaultSelection(
        widget.storeData,
        isAdvancedMode: widget.isAdvancedMode,
      );
      
      print('🎯 Sélection calculée: $smartSelection');

      _localStoreVisibility = Map.fromEntries(
        widget.storeData.entries.map((entry) {
          final storeId = entry.key;
          final shouldBeVisible = smartSelection.contains(storeId);
          print('   - Magasin $storeId (${entry.value.storeName}): $shouldBeVisible');
          return MapEntry(storeId, shouldBeVisible);
        }),
      );

      // ✅ Notifier le parent des nouvelles sélections
      print('📢 Notification du parent...');
      for (final entry in widget.storeData.entries) {
        final storeId = entry.key;
        final shouldBeVisible = smartSelection.contains(storeId);
        print('   -> onStoreToggled($storeId, $shouldBeVisible)');
        widget.onStoreToggled(storeId, shouldBeVisible);
      }
    }
    
    print('✅ _localStoreVisibility final: $_localStoreVisibility');
    print('=' * 50);
  }

  // lib/widgets/chart_components/store_selector.dart - Reset forcé
void _forceSmartInitialization() {
  print('🔄 FORCE Smart Initialization');
  
  _bestPriceStoreId = StoreComparisonService.findBestPriceStoreId(widget.storeData);
  
  final smartSelection = StoreComparisonService.calculateSmartDefaultSelection(
    widget.storeData,
    isAdvancedMode: widget.isAdvancedMode,
  );
  
  print('🎯 Sélection forcée: $smartSelection');
  print('🏆 Champion: $_bestPriceStoreId');
  
  _localStoreVisibility = Map.fromEntries(
    widget.storeData.entries.map((entry) {
      final storeId = entry.key;
      final shouldBeVisible = smartSelection.contains(storeId);
      return MapEntry(storeId, shouldBeVisible);
    }),
  );

  // ✅ Notifier le parent
  for (final entry in widget.storeData.entries) {
    final storeId = entry.key;
    final shouldBeVisible = smartSelection.contains(storeId);
    widget.onStoreToggled(storeId, shouldBeVisible);
  }
  
  setState(() {}); // Force rebuild
}

  @override
  Widget build(BuildContext context) {
    // ✅ Même système pour les deux modes, juste style différent
    if (widget.isAdvancedMode) {
      return _buildAdvancedStyle(context);
    } else {
      return _buildNormalStyle(context);
    }
  }

  Widget _buildNormalStyle(BuildContext context) {
    final visibleStores = _localStoreVisibility.values.where((v) => v).length;
    final totalStores = widget.storeData.length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIGNE 1 : Titre + Actions
          Row(
            children: [
              Icon(Icons.store, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'Magasins à comparer',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
            ],
          ),
          Row(
            children: [
              _buildInlineActionButtons(),
            ],
          ),
          
          // LIGNE 3 : Compteur
          const SizedBox(height: 8),
          Text(
            '$visibleStores/$totalStores magasins sélectionnés',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // ✅ GRILLE FIXE au lieu de Wrap
          _buildStoreGrid(isCompactMode: true),
        ],
      ),
    );
  }

  Widget _buildAdvancedStyle(BuildContext context) {
    final visibleStores = _localStoreVisibility.values.where((v) => v).length;
    final totalStores = widget.storeData.length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIGNE 1 : Titre + Actions
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Comparaison magasins',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              _buildInlineActionButtons(),
            ],
          ),
          
          // LIGNE 2 : Compteur
          const SizedBox(height: 8),
          Text(
            '$visibleStores/$totalStores magasins sélectionnés',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // ✅ GRILLE FIXE au lieu de Wrap
          _buildStoreGrid(isCompactMode: false),
          
          // Stats inchangées
          if (visibleStores > 0) ...[
            const SizedBox(height: 12),
            _buildAdvancedStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedStats() {
    final visibleStores = widget.storeData.values.where((s) => _localStoreVisibility[s.storeId] == true).toList();
    
    if (visibleStores.isEmpty) return const SizedBox.shrink();
    
    // Calculer quelques stats rapides
    final totalDataPoints = visibleStores.fold<int>(0, (sum, store) => sum + store.prices.length);
    final avgDataPointsPerStore = totalDataPoints / visibleStores.length;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: Colors.blue.shade600, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$totalDataPoints points de données • ${avgDataPointsPerStore.toStringAsFixed(1)} pts/magasin en moyenne',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineActionButtons() {
    final allVisible = _localStoreVisibility.values.every((v) => v);
    final hasSelection = _localStoreVisibility.values.any((v) => v);
    final someSelected = hasSelection && !allVisible;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Bouton "Tout"
        _ActionButton(
          label: 'Tout',
          icon: Icons.select_all,
          isActive: allVisible,
          color: Colors.green,
          onPressed: !allVisible ? () => _selectAll(true) : null,
        ),
        const SizedBox(width: 4),
        
        // ✅ Bouton "Aucun"
        _ActionButton(
          label: 'Aucun',
          icon: Icons.clear_all,
          isActive: !hasSelection,
          color: Colors.red,
          onPressed: hasSelection ? () => _selectAll(false) : null,
        ),
        
        // ✅ Bouton "Inverser" (si au moins quelques sélections)
        if (someSelected) ...[
          const SizedBox(width: 4),
          _ActionButton(
            label: 'Inverser',
            icon: Icons.swap_horiz,
            isActive: false,
            color: Colors.blue,
            onPressed: () => _invertSelection(),
          ),
        ],
      ],
    );
  }

  void _toggleStore(int storeId, bool isVisible) {
    setState(() {
      _localStoreVisibility[storeId] = isVisible;
    });
    widget.onStoreToggled(storeId, isVisible);
  }

  void _selectAll(bool isVisible) {
    setState(() {
      for (final storeId in widget.storeData.keys) {
        _localStoreVisibility[storeId] = isVisible;
        widget.onStoreToggled(storeId, isVisible);
      }
    });
  }

  void _invertSelection() {
    setState(() {
      for (final storeId in widget.storeData.keys) {
        final newValue = !(_localStoreVisibility[storeId] ?? false);
        _localStoreVisibility[storeId] = newValue;
        widget.onStoreToggled(storeId, newValue);
      }
    });
  }
  //  Grille fixe
Widget _buildStoreGrid({required bool isCompactMode}) {
  final storeEntries = widget.storeData.entries.toList();
  final storeCount = storeEntries.length;
  
  // ✅ CORRIGÉ : Maximum 2 colonnes pour la lisibilité
  int crossAxisCount;
  
  if (storeCount == 1) {
    crossAxisCount = 1; // 1 seul magasin = 1 colonne
  } else {
    crossAxisCount = 2; // ✅ Toujours 2 colonnes maximum
  }
  
  final rowCount = (storeCount / crossAxisCount).ceil();
  final itemHeight = isCompactMode ? 36.0 : 40.0; // ✅ Légèrement plus haut pour plus de confort
  final spacing = 8.0; // ✅ Espacement légèrement augmenté
  final gridHeight = (rowCount * itemHeight) + ((rowCount - 1) * spacing);
    
  return SizedBox(
    height: gridHeight,
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isCompactMode ? 3.5 : 3.2, // ✅ Ratio plus large pour 2 colonnes
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: storeCount,
      itemBuilder: (context, index) {
        final entry = storeEntries[index];
        final storeId = entry.key;
        final data = entry.value;
        
        return _UnifiedStoreChip(
          storeData: data,
          isVisible: _localStoreVisibility[storeId] ?? false,
          onToggled: (isVisible) => _toggleStore(storeId, isVisible),
          isCompactMode: isCompactMode,
          isBestPrice: storeId == _bestPriceStoreId,
        );
      },
    ),
  );
}
}

// ✅ Chip unifié avec mode compact/détaillé
class _UnifiedStoreChip extends StatelessWidget {
  final StoreChartData storeData;
  final bool isVisible;
  final Function(bool) onToggled;
  final bool isCompactMode;
  final bool isBestPrice;

  const _UnifiedStoreChip({
    required this.storeData,
    required this.isVisible,
    required this.onToggled,
    required this.isCompactMode,
    this.isBestPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    final latestPrice = StoreComparisonService.getLatestPrice(storeData);
    
    return SizedBox(
      width: double.infinity,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Indicateur couleur avec couronne (plus visible)
            Stack(
              children: [
                Container(
                  width: isCompactMode ? 12 : 14, // ✅ Légèrement plus grand
                  height: isCompactMode ? 12 : 14,
                  decoration: BoxDecoration(
                    color: storeData.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (isBestPrice)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Icon(
                      Icons.star,
                      size: 10, // ✅ Étoile plus visible
                      color: Colors.amber.shade600,
                    ),
                  ),
              ],
            ),
            SizedBox(width: isCompactMode ? 6 : 8), // ✅ Plus d'espace
            
            // ✅ Nom du magasin avec icône champion
            Expanded(
              child: Row(
                children: [
                  if (isBestPrice) ...[
                    Icon(
                      Icons.emoji_events,
                      size: isCompactMode ? 12 : 14, // ✅ Plus visible
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      storeData.storeName,
                      style: TextStyle(
                        fontSize: isCompactMode ? 12 : 13, // ✅ Texte plus lisible
                        fontWeight: isBestPrice ? FontWeight.w700 : FontWeight.w500,
                        color: isBestPrice ? Colors.amber.shade800 : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            // ✅ Compteur + prix actuel (plus d'espace disponible)
            if (storeData.prices.isNotEmpty) ...[
              const SizedBox(width: 8), // ✅ Plus d'espace
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '(${storeData.prices.length})',
                    style: TextStyle(
                      fontSize: isCompactMode ? 9 : 10, // ✅ Plus lisible
                      color: Colors.grey.shade600,
                    ),
                  ),
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
              ),
            ],
            
            // ✅ Indicateur de qualité (plus visible)
            if (!isCompactMode && storeData.prices.isNotEmpty) ...[
              const SizedBox(width: 6),
              _buildQualityIndicator(),
            ],
          ],
        ),
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
        // ✅ Padding ajusté pour 2 colonnes
        labelPadding: EdgeInsets.symmetric(
          horizontal: isCompactMode ? 6 : 8,
          vertical: isCompactMode ? 2 : 4,
        ),
      ),
    );
  }

  Widget _buildQualityIndicator() {
    final dataCount = storeData.prices.length;
    Color color;
    
    if (dataCount >= 10) {
      color = Colors.green;
    } else if (dataCount >= 5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      width: 8, // ✅ Plus visible
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isActive 
                ? color.withValues(alpha: 0.2)
                : (onPressed != null ? color.withValues(alpha: 0.1) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive 
                  ? color 
                  : (onPressed != null ? color.withValues(alpha: 0.3) : Colors.grey.shade300),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: onPressed != null ? color : Colors.grey.shade400,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: onPressed != null ? color : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

