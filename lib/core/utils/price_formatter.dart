/// Returns a display-ready price string based on [priceType].
///
/// Examples:
///   formatPrice('100₪', 'קבוע')       → '100₪ כולל'
///   formatPrice('50₪',  'לשעה')       → '50₪ / שעה'
///   formatPrice('',     'לפי הסכמה') → 'לפי הסכמה'
String formatPrice(String priceText, String priceType) {
  if (priceType == 'לפי הסכמה') return 'לפי הסכמה';
  final base = priceText.replaceAll('₪', '').trim();
  if (base.isEmpty) return priceText;
  if (priceType == 'לשעה') return '$base₪ / שעה';
  return '$base₪ כולל';
}

/// Ensures [value] always displays with the ₪ symbol.
/// Strips any existing ₪ then prepends it, so "100", "₪100", "100₪" → "₪100".
/// Returns empty string unchanged.
String withShekel(String value) {
  final trimmed = value.replaceAll('₪', '').trim();
  if (trimmed.isEmpty) return value;
  return '$trimmed₪';
}
