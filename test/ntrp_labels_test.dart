import 'package:flutter_test/flutter_test.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';

void main() {
  test('ntrpValueLabel formats pt-BR decimals', () {
    expect(ntrpValueLabel(3.5), '3,5');
    expect(ntrpValueLabel(4.0), '4,0');
  });

  test('level ladder maps every half step from 1.0 to 5.0', () {
    expect(ntrpLevelName(1.0), 'Iniciante');
    expect(ntrpLevelName(1.5), 'Iniciante+');
    expect(ntrpLevelName(3.0), 'Intermediário');
    expect(ntrpLevelName(3.5), 'Intermediário forte');
    expect(ntrpLevelName(5.0), 'Competição');
    // Out-of-range values clamp instead of throwing.
    expect(ntrpLevelName(0.5), 'Iniciante');
    expect(ntrpLevelName(7.0), 'Competição');
    for (var v = 1.0; v <= 5.0; v += 0.5) {
      expect(ntrpLevelDescription(v), isNotEmpty);
    }
  });

  test('category label keeps legacy buckets', () {
    expect(ntrpCategoryLabel(1.5), 'Iniciante');
    expect(ntrpCategoryLabel(3.5), 'Intermediário');
    expect(ntrpCategoryLabel(5.0), 'Profissional');
  });
}
