import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reputation Calculation Logic', () {
    test('calculate new average rating correctly', () {
      double currentRating = 4.0;
      int currentCount = 1;
      double newReviewRating = 5.0;

      int nextCount = currentCount + 1;
      double nextRating = ((currentRating * currentCount) + newReviewRating) / nextCount;

      expect(nextRating, 4.5);
    });

    test('update tag frequencies correctly', () {
      Map<String, int> frequencies = {'Punctual': 1};
      List<String> newTags = ['Punctual', 'Gentle'];

      for (var tag in newTags) {
        frequencies[tag] = (frequencies[tag] ?? 0) + 1;
      }

      expect(frequencies['Punctual'], 2);
      expect(frequencies['Gentle'], 1);
    });
  });
}
