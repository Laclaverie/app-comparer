import 'package:client_price_comparer/widgets/chart_components/grid_store_layout.dart';
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

// lib/widgets/chart_components/store_selector.dart - Widget simple
class _StoreSelectorState extends State<StoreSelector> {
  Map<int, bool> _localStoreVisibility = {};
  Set<int> _bestPriceStoreIds = {};

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  @override
  void didUpdateWidget(StoreSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeData != widget.storeData) {
      _initializeSelection();
    }
  }

  /// ✅ Initialisation simple via le service
  void _initializeSelection({bool forceReset = false}) {
    final result = StoreComparisonService.initializeStoreSelection(
      widget.storeData,
      isAdvancedMode: widget.isAdvancedMode,
      forceReset: forceReset,
    );

    setState(() {
      _localStoreVisibility = result.visibility;
      _bestPriceStoreIds = result.bestPriceStoreIds;
    });

    // Notifier le parent seulement si sélection intelligente appliquée
    if (result.selectionType == SelectionType.smart && result.smartSelectedIds != null) {
      for (final storeId in widget.storeData.keys) {
        final shouldBeVisible = result.smartSelectedIds!.contains(storeId);
        widget.onStoreToggled(storeId, shouldBeVisible);
      }
    }
  }

  /// ✅ Actions simplifiées
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
        final currentVisibility = _localStoreVisibility[storeId] ?? false;
        final newVisibility = !currentVisibility;
        _localStoreVisibility[storeId] = newVisibility;
        widget.onStoreToggled(storeId, newVisibility);
      }
    });
  }

  // ✅ Build methods inchangés mais plus lisibles
  @override
  Widget build(BuildContext context) {
    return widget.isAdvancedMode 
        ? _buildAdvancedStyle(context) 
        : _buildNormalStyle(context);
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

  /// ✅ Grille simplifiée
  Widget _buildStoreGrid({required bool isCompactMode}) {
    return GridStoreLayout(
      storeData: widget.storeData,
      visibility: _localStoreVisibility,
      bestPriceStoreIds: _bestPriceStoreIds,
      isCompactMode: isCompactMode,
      onStoreToggled: _toggleStore,
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

