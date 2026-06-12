import 'package:conectenis_app/shared/models/enums.dart';

/// Human-readable challenge status, including spec lifecycle reasons from API.
String challengeDisplayStatusLabel({
  required ChallengeStatus status,
  String? apiStatusLabel,
  String? declinedReason,
  String? cancelledReason,
  String? closedReason,
}) {
  if (apiStatusLabel != null && apiStatusLabel.isNotEmpty) {
    return apiStatusLabel;
  }
  if (status == ChallengeStatus.declined && declinedReason == 'inertia') {
    return 'Recusado por Inércia';
  }
  if (status == ChallengeStatus.cancelled && cancelledReason == 'auto_timeout') {
    return 'Cancelado Automaticamente';
  }
  if (status == ChallengeStatus.expired && closedReason == 'no_score_24h') {
    return 'Encerrado Sem Lançamento';
  }
  return status.label;
}
