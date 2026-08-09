/// Human-readable NTRP category for compact display.
String ntrpCategoryLabel(double rating) {
  if (rating < 2.0) return 'Iniciante';
  if (rating < 3.0) return 'Principiante';
  if (rating < 4.0) return 'Intermediário';
  if (rating < 5.0) return 'Avançado';
  return 'Profissional';
}

String ntrpLevelDisplay(double rating) {
  return '${ntrpCategoryLabel(rating)} (${rating.toStringAsFixed(1)})';
}

/// NTRP formatted pt-BR: 3.5 → "3,5".
String ntrpValueLabel(double rating) =>
    rating.toStringAsFixed(1).replaceAll('.', ',');

/// Prototype level ladder - one entry per half step, 1.0 → 5.0.
const _ntrpLevels = <(String, String)>[
  ('Iniciante', 'Começando agora; aprendendo os golpes básicos.'),
  ('Iniciante+', 'Troca bolas curtas; saque em desenvolvimento.'),
  ('Básico', 'Sustenta rallies lentos com consistência.'),
  ('Básico+', 'Boa direção de bola; jogo de rede em construção.'),
  ('Intermediário', 'Golpes confiáveis dos dois lados; começa a jogar taticamente.'),
  ('Intermediário forte', 'Varia efeitos e profundidade; saque com direção.'),
  ('Avançado', 'Controla ritmo e construção de pontos.'),
  ('Avançado forte', 'Golpes de pressão; poucos erros não forçados.'),
  ('Competição', 'Nível de torneios federados; jogo completo.'),
];

int _ntrpIndex(double rating) =>
    (((rating - 1.0) / 0.5).round()).clamp(0, _ntrpLevels.length - 1);

/// Short level name for an NTRP value ("Intermediário forte").
String ntrpLevelName(double rating) => _ntrpLevels[_ntrpIndex(rating)].$1;

/// One-line description of the level, from the prototype ladder.
String ntrpLevelDescription(double rating) =>
    _ntrpLevels[_ntrpIndex(rating)].$2;
