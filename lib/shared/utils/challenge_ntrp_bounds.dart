import 'package:conectenis_app/shared/widgets/ntrp_rating_picker.dart';

/// Allowed NTRP window when creating a public challenge: creator level ± 1 star.
class ChallengeNtrpBounds {
  ChallengeNtrpBounds._();

  static const double starOffset = 1.0;

  static double allowedMin(double userNtrp) {
    return (userNtrp - starOffset).clamp(
      NtrpRatingPicker.minRating,
      NtrpRatingPicker.maxRating,
    );
  }

  static double allowedMax(double userNtrp) {
    return (userNtrp + starOffset).clamp(
      NtrpRatingPicker.minRating,
      NtrpRatingPicker.maxRating,
    );
  }

  static bool isValidRange({
    required double userNtrp,
    required double minNtrp,
    required double maxNtrp,
  }) {
    final lo = allowedMin(userNtrp);
    final hi = allowedMax(userNtrp);
    return minNtrp >= lo && maxNtrp <= hi && minNtrp <= maxNtrp;
  }

  static int sliderDivisions(double allowedMin, double allowedMax) {
    if (allowedMax <= allowedMin) return 0;
    return ((allowedMax - allowedMin) / 0.5).round();
  }
}
