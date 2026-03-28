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
