import 'package:flutter_test/flutter_test.dart';
import 'package:kooki/models/nutritionist_stats_model.dart';

void main() {
  test('NutritionistStats computes approval ratio and weekly max', () {
    final stats = NutritionistStats(
      totalValidated: 8,
      approved: 6,
      rejected: 2,
      weekdayCounts: [1, 4, 2, 0, 3, 2, 1],
    );

    expect(stats.approvalRatio, 0.75);
    expect(stats.weekMax, 4);
  });

  test(
    'NutritionistStats avoids division by zero when there are no reviews',
    () {
      final stats = NutritionistStats(
        totalValidated: 0,
        approved: 0,
        rejected: 0,
        weekdayCounts: const [],
      );

      expect(stats.approvalRatio, 0.0);
      expect(stats.weekMax, 1);
    },
  );
}
