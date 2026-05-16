enum SkillLevel {
  beginner('beginner', 'Iniciante'),
  intermediate('intermediate', 'Intermediário'),
  advanced('advanced', 'Avançado');

  const SkillLevel(this.value, this.label);
  final String value;
  final String label;

  static SkillLevel fromValue(String? value) => SkillLevel.values.firstWhere(
        (e) => e.value == value,
        orElse: () => SkillLevel.intermediate,
      );
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

enum MapFilter { players, courts }
