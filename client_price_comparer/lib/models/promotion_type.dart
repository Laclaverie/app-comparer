/// Defines the different types of promotional offers available in the price comparison system
/// Each type represents a different discount mechanism with specific calculation rules
enum PromotionType {
  /// Standard percentage discount applied to the base price
  /// Example: 20% off - reduces price by 20% (€4.00 becomes €3.20)
  /// Parameters: percentage (double)
  percentageDiscount,
  
  /// Fixed amount discount subtracted from the base price
  /// Example: €2 off - reduces price by fixed amount (€4.00 becomes €2.00)
  /// Parameters: amount (double)
  fixedDiscount,
  
  /// Buy a certain quantity and get additional items for free
  /// Example: Buy 3 get 1 free - pay for 3 items, receive 4 total
  /// Effective unit price: original price × (buyQuantity ÷ totalQuantity)
  /// Parameters: buyQuantity (int), getQuantity (int)
  buyXGetY,
  
  /// Fixed bundle pricing - must buy exact quantity for special total price
  /// Example: 2 for €5 - must buy exactly 2 items to pay €5 total
  /// Cannot scale beyond the specified quantity bundle
  /// Parameters: quantity (int), totalPrice (double)
  buyXForY,
  
  /// Bulk pricing tier - minimum quantity threshold for discounted unit price
  /// Example: 3 for €10 - when buying 3+ items, each costs €3.33
  /// Scales with quantity: 6 items = €20.00, 9 items = €30.00
  /// Parameters: quantity (int), totalPrice (double)
  multipleQuantity,
}