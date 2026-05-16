import 'package:conectenis_app/shared/models/court.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/player.dart';

/// Seed data around Jundiaí/SP for alpha demos.
abstract final class MockData {
  static const centerLat = -23.1864;
  static const centerLng = -46.8842;

  static final players = <Player>[
    const Player(
      id: 2,
      name: 'Rafael Costa',
      age: 34,
      skillLevel: SkillLevel.advanced,
      playStyle: PlayStyle.singles,
      latitude: -23.188,
      longitude: -46.882,
      distanceKm: 1.2,
    ),
    const Player(
      id: 3,
      name: 'Mariana Silva',
      age: 28,
      skillLevel: SkillLevel.intermediate,
      playStyle: PlayStyle.both,
      latitude: -23.184,
      longitude: -46.887,
      distanceKm: 0.8,
    ),
    const Player(
      id: 4,
      name: 'Pedro Almeida',
      age: 42,
      skillLevel: SkillLevel.beginner,
      playStyle: PlayStyle.doubles,
      latitude: -23.191,
      longitude: -46.879,
      distanceKm: 2.1,
    ),
    const Player(
      id: 5,
      name: 'Camila Rocha',
      age: 31,
      skillLevel: SkillLevel.intermediate,
      playStyle: PlayStyle.singles,
      latitude: -23.182,
      longitude: -46.891,
      distanceKm: 1.5,
    ),
  ];

  static final courts = <Court>[
    const Court(
      id: 1,
      name: 'Clube Esportivo Jundiaí',
      address: 'Av. Antônio Frederico Ozanan, 1000',
      phone: '(11) 4580-0000',
      city: 'Jundiaí',
      state: 'SP',
      latitude: -23.1855,
      longitude: -46.886,
      distanceKm: 0.5,
    ),
    const Court(
      id: 2,
      name: 'Tennis Center Jundiaí',
      address: 'R. Barão de Teffé, 450',
      phone: '(11) 4581-1234',
      city: 'Jundiaí',
      state: 'SP',
      latitude: -23.189,
      longitude: -46.881,
      distanceKm: 1.0,
    ),
    const Court(
      id: 3,
      name: 'Quadra Pública do Parque da Cidade',
      address: 'Parque da Cidade',
      city: 'Jundiaí',
      state: 'SP',
      latitude: -23.192,
      longitude: -46.888,
      distanceKm: 1.8,
    ),
  ];
}
