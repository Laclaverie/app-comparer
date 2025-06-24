// apps/client/lib/widgets/product_details/product_action_buttons_widget.dart
import 'package:flutter/material.dart';
import 'package:client_price_comparer/services/product_details_service.dart';

class ProductActionButtonsWidget extends StatefulWidget {
  final int productId;
  final ProductDetailsService productDetailsService;
  final VoidCallback? onPriceAlert;
  final VoidCallback? onDelete;

  const ProductActionButtonsWidget({
    super.key,
    required this.productId,
    required this.productDetailsService,
    this.onPriceAlert,
    this.onDelete,
  });

  @override
  State<ProductActionButtonsWidget> createState() => _ProductActionButtonsWidgetState();
}

class _ProductActionButtonsWidgetState extends State<ProductActionButtonsWidget> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    // TODO: Implémenter la vérification du statut favori
    // Pour l'instant, simuler
    setState(() {
      _isFavorite = false; // Default value
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await widget.productDetailsService.addToFavorites(widget.productId);
      if (success) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFavorite ? 'Added to favorites' : 'Removed from favorites',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareProduct() {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportData() {
    // TODO: Implémenter l'export des données
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
                  Icons.settings_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Product Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary Actions Row
            Row(
              children: [
                // Favorite Button
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_outline,
                    label: _isFavorite ? 'Favorited' : 'Add to Favorites',
                    color: _isFavorite ? Colors.red : Colors.grey[600]!,
                    onPressed: _isLoading ? null : _toggleFavorite,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Price Alert Button
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Set Price Alert',
                    color: Colors.blue[600]!,
                    onPressed: widget.onPriceAlert,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Secondary Actions Row
            Row(
              children: [
                // Share Button
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.share_outlined,
                    label: 'Share Product',
                    color: Colors.green[600]!,
                    onPressed: _shareProduct,
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Export Button
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.download_outlined,
                    label: 'Export Data',
                    color: Colors.orange[600]!,
                    onPressed: _exportData,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Danger Zone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_outlined, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once deleted, this product and all its price history will be permanently removed.',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Product'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isSecondary = false,
  }) {
    if (isSecondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        elevation: 2,
      ),
    );
  }
}