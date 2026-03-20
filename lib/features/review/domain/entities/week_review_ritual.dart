import 'package:beltech/features/review/domain/entities/week_review_data.dart';

class WeekReviewRitual {
  const WeekReviewRitual({
    required this.headline,
    required this.summary,
    required this.focusLabel,
    required this.focusDetail,
    required this.tone,
    required this.ctaLabel,
  });

  final String headline;
  final String summary;
  final String focusLabel;
  final String focusDetail;
  final WeekReviewInsightTone tone;
  final String ctaLabel;
}
