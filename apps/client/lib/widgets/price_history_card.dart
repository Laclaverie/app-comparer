import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'price_history_chart.dart';
import 'price_history_timeline.dart';
import 'shared/mock_data_helpers.dart';
import 'shared/price_formatting_helpers.dart';

enum PriceHistoryView { chart, timeline }

class PriceHistoryCard extends StatefulWidget {
  final ProductDto product;
  final bool isAdvancedMode;

  const PriceHistoryCard({
    super.key,
    required this.product,
    required this.isAdvancedMode,
  });

  @override
  State<PriceHistoryCard> createState() => _PriceHistoryCardState();
}

class _PriceHistoryCardState extends State<PriceHistoryCard> {
  List<PriceHistoryDto>? _priceHistory;
  bool _isLoading = true;
  String? _error;
  PriceHistoryView _currentView = PriceHistoryView.chart;
  int _selectedPeriodDays = 30; // 30 jours par défaut

  final List<int> _periodOptions = [7, 14, 30, 60, 90, 180];

  @override
  void initState() {
    super.initState();
    _loadPriceHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (widget.isAdvancedMode) ...[
              _buildControls(context),
              const SizedBox(height: 16),
            ],
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.trending_up,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Historique des prix',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPriceHistory,
            tooltip: 'Actualiser l\'historique',
          ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Column(
      children: [
        // Sélecteur de vue
        Row(
          children: [
            Text(
              'Affichage : ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<PriceHistoryView>(
              segments: const [
                ButtonSegment(
                  value: PriceHistoryView.chart,
                  icon: Icon(Icons.show_chart, size: 16),
                  label: Text('Graphique'),
                ),
                ButtonSegment(
                  value: PriceHistoryView.timeline,
                  icon: Icon(Icons.timeline, size: 16),
                  label: Text('Timeline'),
                ),
              ],
              selected: {_currentView},
              onSelectionChanged: (Set<PriceHistoryView> selection) {
                setState(() {
                  _currentView = selection.first;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Sélecteur de période
        Row(
          children: [
            Text(
              'Période : ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: _periodOptions.map((days) {
                  final isSelected = days == _selectedPeriodDays;
                  return FilterChip(
                    label: Text('${days}j'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriodDays = days;
                        });
                        _loadPriceHistory();
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    if (_priceHistory == null || _priceHistory!.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildHistoryView(context);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de l\'historique...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.red[600]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadPriceHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun historique disponible',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'historique des prix sera visible une fois que nous aurons collecté des données',
              style: TextStyle(color: Colors.orange[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Période sélectionnée : $_selectedPeriodDays jours',
              style: TextStyle(
                color: Colors.orange[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView(BuildContext context) {
    final filteredHistory = _getFilteredHistory();
    
    return Column(
      children: [
        // Statistiques rapides
        _buildQuickStats(context, filteredHistory),
        const SizedBox(height: 16),
        
        // Vue sélectionnée
        if (_currentView == PriceHistoryView.chart)
          PriceHistoryChart(
            priceHistory: filteredHistory,
            selectedPeriodDays: _selectedPeriodDays,
            isAdvancedMode: widget.isAdvancedMode,
          )
        else
          PriceHistoryTimeline(
            priceHistory: filteredHistory,
            isAdvancedMode: widget.isAdvancedMode,
          ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, List<PriceHistoryDto> history) {
    if (history.length < 2) return const SizedBox.shrink();
    
    final oldestPrice = history.last.price;
    final newestPrice = history.first.price;
    final difference = newestPrice - oldestPrice;
    final percentChange = ((difference / oldestPrice) * 100);
    
    final isPositive = difference > 0;
    final color = isPositive ? Colors.red : Colors.green;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Évolution sur $_selectedPeriodDays jours',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${PriceFormattingHelpers.formatPrice(difference.abs())}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PriceHistoryDto> _getFilteredHistory() {
    if (_priceHistory == null) return [];
    
    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedPeriodDays));
    return _priceHistory!
        .where((price) => price.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Plus récent en premier
  }

  Future<void> _loadPriceHistory() async {
    print('🔍 PRICE_HISTORY: Loading history for product ${widget.product.barcode} (${_selectedPeriodDays} days)');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ TODO : Remplacer par l'appel API réel
      await Future.delayed(const Duration(milliseconds: 800)); // Simulation
      
      // ✅ DONNÉES MOCK pour test
      _priceHistory = MockDataHelpers.generateMockPriceHistory(
        widget.product.id!,
        _selectedPeriodDays,
      );
      
      print('✅ PRICE_HISTORY: Loaded ${_priceHistory!.length} price entries');
    } catch (e) {
      print('❌ PRICE_HISTORY ERROR: $e');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}