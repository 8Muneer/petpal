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

/// Parses the leading numeric amount out of a price string.
///   '80₪' → 80, '₪120.5' → 120.5, 'לפי הסכמה' → null
double? parsePriceAmount(String? priceText) {
  if (priceText == null) return null;
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(priceText.replaceAll(',', ''));
  if (match == null) return null;
  return double.tryParse(match.group(0)!);
}

String _amount(num v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

/// Display-ready agreed price for a booking, multiplying the provider's unit
/// rate by the requested units when it makes sense:
///   - walk priced 'לשעה' + [hours]  → 'total₪ (N שעות × rate₪)'
///   - sitting (any concrete price) + [nights] → 'total₪ (N לילות × rate₪)'
///   - 'לפי הסכמה', or no parseable rate → falls back to [formatPrice].
/// Pass only the unit relevant to the service (hours for walk, nights for
/// sitting); leave the other null.
String bookingPriceLabel({
  required String? priceText,
  required String? priceType,
  int? hours,
  int? nights,
}) {
  final type = priceType ?? '';
  if (type == 'לפי הסכמה') return 'לפי הסכמה';
  final rate = parsePriceAmount(priceText);
  if (rate == null) return formatPrice(priceText ?? '', type);

  if (hours != null && hours > 0 && type == 'לשעה') {
    return '${_amount(rate * hours)}₪ ($hours שעות × ${_amount(rate)}₪)';
  }
  if (nights != null && nights > 0) {
    return '${_amount(rate * nights)}₪ ($nights לילות × ${_amount(rate)}₪)';
  }
  return formatPrice(priceText ?? '', type);
}

/// Ensures [value] always displays with the ₪ symbol.
/// Strips any existing ₪ then prepends it, so "100", "₪100", "100₪" → "₪100".
/// Returns empty string unchanged.
String withShekel(String value) {
  final trimmed = value.replaceAll('₪', '').trim();
  if (trimmed.isEmpty) return value;
  return '$trimmed₪';
}
