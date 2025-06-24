import 'package:client_price_comparer/services/charts/store_comparison_service.dart';
import 'package:client_price_comparer/widgets/chart_components/multi_store_chart_painter.dart';
import 'package:client_price_comparer/widgets/chart_components/price_chart_axes.dart';
import 'package:client_price_comparer/widgets/chart_components/store_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import '../services/charts/price_chart_data_service.dart';
import '../services/charts/price_statistics_service.dart';
import 'shared/price_formatting_helpers.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PriceHistoryDto> priceHistory;
  final int selectedPeriodDays;
  final bool isAdvancedMode;

  const PriceHistoryChart({
    super.key,
    required this.priceHistory,
    required this.selectedPeriodDays,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return _buildEmptyChart(context);
    }

    final chartData = PriceChartDataService.prepareChartData(priceHistory, isAdvancedMode);

    return Container(
      height: isAdvancedMode ? 800 : 500, // +200px mode avancé, +200px mode normal
      width: double.infinity, // ✅ Prendre toute la largeur disponible
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _PriceChartHeader(chartData: chartData, isAdvancedMode: isAdvancedMode),
          const SizedBox(height: 16),
          Expanded(
            // ✅ Le graphique prend le maximum d'espace
            flex: 5, // Encore plus d'espace pour le graphique
            child: _PriceChartCanvas(
              priceHistory: priceHistory, 
              isAdvancedMode: isAdvancedMode, 
              selectedPeriodDays: selectedPeriodDays
            ),
          ),
          const SizedBox(height: 12),
          if (isAdvancedMode) ...[
            Flexible(
              flex: 1,
              child: SingleChildScrollView(
                child: _PriceChartAdvancedStats(chartData: chartData),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _PriceChartFooter(
            selectedPeriodDays: selectedPeriodDays, 
            dataPointsCount: chartData.sortedHistory.length, 
            isAdvancedMode: isAdvancedMode
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 500, // ✅ Grand même quand vide
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey.shade400), // ✅ Icône encore plus grande
            const SizedBox(height: 16),
            Text(
              'Pas assez de données pour le graphique',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18, // ✅ Texte plus grand
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des prix pour voir l\'évolution',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Composants séparés pour chaque partie
class _PriceChartHeader extends StatelessWidget {
  final PriceChartData chartData;
  final bool isAdvancedMode;

  const _PriceChartHeader({
    required this.chartData,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    final stats = chartData.stats.basicStats;
    
    if (!isAdvancedMode) {
      return _buildSimpleHeader(stats);
    }
    
    return _buildAdvancedHeader(context, chartData);
  }

  Widget _buildSimpleHeader(BasicPriceStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Min: ${PriceFormattingHelpers.formatPrice(stats.minPrice)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Max: ${PriceFormattingHelpers.formatPrice(stats.maxPrice)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Moyenne',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              PriceFormattingHelpers.formatPrice(stats.avgPrice),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedHeader(BuildContext context, PriceChartData chartData) {
    // Implementation avancée...
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Analyse avancée',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Trend indicator si disponible
          ],
        ),
        const SizedBox(height: 12),
        // Stats cards...
      ],
    );
  }
}

class _PriceChartCanvas extends StatefulWidget {
  final List<PriceHistoryDto> priceHistory;
  final bool isAdvancedMode;
  final int selectedPeriodDays;

  const _PriceChartCanvas({
    required this.priceHistory,
    required this.isAdvancedMode,
    required this.selectedPeriodDays,
  });

  @override
  State<_PriceChartCanvas> createState() => _PriceChartCanvasState();
}

class _PriceChartCanvasState extends State<_PriceChartCanvas> {
  Map<int, StoreChartData> _storeData = {};
  Map<int, List<Offset>> _storePoints = {};
  BasicPriceStats _globalStats = BasicPriceStats.empty();

  @override
  void initState() {
    super.initState();
    _updateChartData();
  }

  @override
  void didUpdateWidget(_PriceChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.priceHistory != widget.priceHistory) {
      _updateChartData();
    }
  }

  void _updateChartData() {
    _storeData = StoreComparisonService.groupPricesByStore(widget.priceHistory);
    _globalStats = StoreComparisonService.calculateGlobalStats(_storeData);
    _storePoints = StoreComparisonService.calculateMultiStorePoints(_storeData, _globalStats);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sélecteur de magasins
        StoreSelector(
          storeData: _storeData,
          onStoreToggled: _onStoreToggled,
          isAdvancedMode: widget.isAdvancedMode,
        ),
        const SizedBox(height: 12),
        
        // Graphique avec axes
        Expanded(
          child: Stack(
            children: [
              // Axes
              Positioned.fill(
                child: PriceChartAxes(
                  stats: _globalStats,
                  selectedPeriodDays: widget.selectedPeriodDays,
                  chartSize: Size.infinite,
                  isAdvancedMode: widget.isAdvancedMode,
                ),
              ),
              
              // Graphique principal
              Positioned.fill(
                child: CustomPaint(
                  painter: MultiStoreChartPainter(
                    storeData: _storeData,
                    storePoints: _storePoints,
                    globalStats: _globalStats,
                    isAdvancedMode: widget.isAdvancedMode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onStoreToggled(int storeId, bool isVisible) {
    setState(() {
      _storeData[storeId] = _storeData[storeId]!.copyWith(isVisible: isVisible);
      _globalStats = StoreComparisonService.calculateGlobalStats(_storeData);
      _storePoints = StoreComparisonService.calculateMultiStorePoints(_storeData, _globalStats);
    });
  }
}

class _PriceChartFooter extends StatelessWidget {
  final int selectedPeriodDays;
  final int dataPointsCount;
  final bool isAdvancedMode;

  const _PriceChartFooter({
    required this.selectedPeriodDays,
    required this.dataPointsCount,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Il y a ${selectedPeriodDays}j',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        if (isAdvancedMode && dataPointsCount > 0) ...[
          Text(
            '$dataPointsCount points de données',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        Text(
          'Aujourd\'hui',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _PriceChartAdvancedStats extends StatelessWidget {
  final PriceChartData chartData;

  const _PriceChartAdvancedStats({required this.chartData});

  @override
  Widget build(BuildContext context) {
    // Stats avancées pour mode avancé
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Distribution, tendance, etc.
        ],
      ),
    );
  }
}