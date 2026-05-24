enum Gender {
  male('male', 'Masculino'),
  female('female', 'Feminino');

  const Gender(this.value, this.label);
  final String value;
  final String label;

  static Gender? fromValue(String? value) {
    if (value == null || value.isEmpty || value == 'prefer_not_to_say') {
      return null;
    }
    for (final gender in Gender.values) {
      if (gender.value == value) return gender;
    }
    return null;
  }
}

enum PlayStyle {
  singles('singles', 'Simples'),
  doubles('doubles', 'Duplas'),
  both('both', 'Ambos');

  const PlayStyle(this.value, this.label);
  final String value;
  final String label;

  static PlayStyle fromValue(String? value) => PlayStyle.values.firstWhere(
        (e) => e.value == value,
        orElse: () => PlayStyle.both,
      );
}

enum MapFilter { players, places }

enum ChallengeType {
  direct('direct', 'Direto'),
  public('public', 'Público');

  const ChallengeType(this.value, this.label);
  final String value;
  final String label;

  static ChallengeType fromValue(String? value) => ChallengeType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => ChallengeType.direct,
      );
}

enum ChallengeFormat {
  singles('singles', 'Simples'),
  doubles('doubles', 'Duplas');

  const ChallengeFormat(this.value, this.label);
  final String value;
  final String label;

  int get slotsTotal => this == ChallengeFormat.singles ? 2 : 4;

  static ChallengeFormat fromValue(String? value) => ChallengeFormat.values.firstWhere(
        (e) => e.value == value,
        orElse: () => ChallengeFormat.singles,
      );
}

enum ChallengeStatus {
  pendingAcceptance('pending_acceptance', 'Pendente aceite'),
  pendingCandidates('pending_candidates', 'Pendente candidatos'),
  candidatesAwaitingAccept('candidates_awaiting_accept', 'Candidatos aguardando'),
  accepted('accepted', 'Aceito'),
  pendingScore('pending_score', 'Pendente placar'),
  completed('completed', 'Realizado'),
  declined('declined', 'Recusado'),
  cancelled('cancelled', 'Cancelado');

  const ChallengeStatus(this.value, this.label);
  final String value;
  final String label;

  static ChallengeStatus fromValue(String? value) => ChallengeStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => ChallengeStatus.pendingAcceptance,
      );
}

enum ChallengeListRole {
  created('created', 'Criados'),
  received('received', 'Recebidos'),
  publicNearby('public_nearby', 'Públicos');

  const ChallengeListRole(this.value, this.label);
  final String value;
  final String label;
}

enum PlayInvitationStatus {
  pending('pending', 'Pendente'),
  accepted('accepted', 'Aceito'),
  declined('declined', 'Recusado'),
  cancelled('cancelled', 'Cancelado'),
  completed('completed', 'Realizado');

  const PlayInvitationStatus(this.value, this.label);
  final String value;
  final String label;

  static PlayInvitationStatus fromValue(String? value) =>
      PlayInvitationStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => PlayInvitationStatus.pending,
      );
}

enum PlaceReportReason {
  badConditions('bad_conditions', 'Quadra/local em más condições que prejudica o jogo'),
  doesNotExist('does_not_exist', 'Local não existe'),
  wrongLocation('wrong_location', 'Pin / localização incorreta no mapa'),
  duplicate('duplicate', 'Local duplicado (já existe outro cadastro)'),
  noAccess('no_access', 'Sem acesso ao local (fechado, privado, inacessível)'),
  incorrectName('incorrect_name', 'Nome enganoso ou incorreto'),
  other('other', 'Outro (obrigatório detalhar no texto)');

  const PlaceReportReason(this.value, this.label);
  final String value;
  final String label;

  static PlaceReportReason fromValue(String? value) =>
      PlaceReportReason.values.firstWhere(
        (e) => e.value == value,
        orElse: () => PlaceReportReason.other,
      );
}

enum UserReportReason {
  skillMismatch('skill_mismatch', 'Nível de jogo não condiz com o perfil'),
  disrespectful('disrespectful', 'Comportamento desrespeitoso'),
  noShow('no_show', 'Não compareceu no horário combinado'),
  harassment('harassment', 'Assédio ou mensagens inadequadas'),
  unsportsmanlike('unsportsmanlike', 'Conduta antidesportiva durante o jogo'),
  other('other', 'Outro (obrigatório detalhar no texto)');

  const UserReportReason(this.value, this.label);
  final String value;
  final String label;

  static UserReportReason fromValue(String? value) =>
      UserReportReason.values.firstWhere(
        (e) => e.value == value,
        orElse: () => UserReportReason.other,
      );
}

enum InvitationListRole {
  all('all', 'Todos'),
  sent('sent', 'Enviados'),
  received('received', 'Recebidos');

  const InvitationListRole(this.value, this.label);
  final String value;
  final String label;
}

enum RankingScope {
  home('home', 'Cidade do perfil'),
  played('played', 'Vitórias na cidade');

  const RankingScope(this.value, this.label);
  final String value;
  final String label;
}
