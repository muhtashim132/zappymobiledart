// Centralised list of business categories used across the app.
// Update this one file and the change propagates everywhere.

class AppCategories {
  static const List<Map<String, String>> all = [
    {'name': 'Grocery',        'emoji': '🛒'},
    {'name': 'Restaurant',     'emoji': '🍽️'},
    {'name': 'Fast Food',      'emoji': '🍔'},
    {'name': 'Bakery',         'emoji': '🥖'},
    {'name': 'Butcher',        'emoji': '🥩'},
    {'name': 'Fish & Seafood', 'emoji': '🐟'},
    {'name': 'Dairy & Eggs',   'emoji': '🥛'},
    {'name': 'Fruits & Vegs',  'emoji': '🥬'},
    {'name': 'Sweets & Mithai','emoji': '🍬'},
    {'name': 'Beverages',      'emoji': '🧃'},
    {'name': 'Pharmacy',       'emoji': '💊'},
    {'name': 'Medical Store',  'emoji': '🏥'},
    {'name': 'Electronics',    'emoji': '📱'},
    {'name': 'Mobile & Repair','emoji': '🔧'},
    {'name': 'Clothing',       'emoji': '👕'},
    {'name': 'Footwear',       'emoji': '👟'},
    {'name': 'Jewellery',      'emoji': '💍'},
    {'name': 'Hardware Store', 'emoji': '🔨'},
    {'name': 'Stationery',     'emoji': '📚'},
    {'name': 'Toys & Games',   'emoji': '🧸'},
    {'name': 'Sports',         'emoji': '⚽'},
    {'name': 'Pet Supplies',   'emoji': '🐾'},
    {'name': 'Salon & Beauty', 'emoji': '💇'},
    {'name': 'Flowers',        'emoji': '🌸'},
    {'name': 'Home Decor',     'emoji': '🏠'},
    {'name': 'Furniture',      'emoji': '🛋️'},
    {'name': 'Auto Parts',     'emoji': '🚗'},
    {'name': 'Paan Shop',      'emoji': '🌿'},
    {'name': 'Tea & Coffee',   'emoji': '☕'},
    {'name': 'Ice Cream',      'emoji': '🍦'},
    {'name': 'Organic',        'emoji': '🌱'},
    {'name': 'Other',          'emoji': '🏪'},
  ];

  /// Flat list of category names (for Supabase queries)
  static List<String> get names => all.map((c) => c['name']!).toList();
}
