import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/play_invitation.dart';
import 'package:conectenis_app/shared/models/player.dart';

/// Seed data around Jundiaí/SP for alpha demos.
abstract final class MockData {
  static const centerLat = -23.1864;
  static const centerLng = -46.8842;

  static const currentUserId = 1;

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

  static final places = <Place>[
    const Place(
      id: 1,
      name: 'Clube Esportivo Jundiaí',
      latitude: -23.1855,
      longitude: -46.886,
      createdByUserId: 1,
      averageRating: 4.5,
      ratingsCount: 12,
      distanceKm: 0.5,
    ),
    const Place(
      id: 2,
      name: 'Tennis Center Jundiaí',
      latitude: -23.189,
      longitude: -46.881,
      createdByUserId: 2,
      averageRating: 4.0,
      ratingsCount: 8,
      distanceKm: 1.0,
    ),
    const Place(
      id: 3,
      name: 'Quadra Pública do Parque da Cidade',
      latitude: -23.192,
      longitude: -46.888,
      createdByUserId: 1,
      ratingsCount: 0,
      distanceKm: 1.8,
    ),
  ];

  static List<PlayInvitation> playInvitations() {
    final rafael = players[0];
    final mariana = players[1];
    final place = places[0];
    return [
      PlayInvitation(
        id: 1,
        status: PlayInvitationStatus.pending,
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
        message: 'Bora jogar um set?',
        inviter: Player(
          id: currentUserId,
          name: 'Você',
          latitude: centerLat,
          longitude: centerLng,
        ),
        invitee: mariana,
        place: place,
        role: 'sent',
      ),
      PlayInvitation(
        id: 2,
        status: PlayInvitationStatus.accepted,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        inviter: rafael,
        invitee: Player(
          id: currentUserId,
          name: 'Você',
          latitude: centerLat,
          longitude: centerLng,
        ),
        place: places[1],
        role: 'received',
      ),
      PlayInvitation(
        id: 3,
        status: PlayInvitationStatus.completed,
        scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedByUserId: currentUserId,
        inviter: Player(
          id: currentUserId,
          name: 'Você',
          latitude: centerLat,
          longitude: centerLng,
        ),
        invitee: players[2],
        place: place,
        role: 'sent',
        hasRatedOpponent: true,
      ),
    ];
  }
}
