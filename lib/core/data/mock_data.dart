import 'package:conectenis_app/shared/models/challenge.dart';
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
      ntrpRating: 4.0,
      gender: Gender.male,
      profession: 'Advogado',
      city: 'Jundiaí',
      state: 'SP',
      playStyle: PlayStyle.singles,
      latitude: -23.188,
      longitude: -46.882,
      distanceKm: 1.2,
    ),
    const Player(
      id: 3,
      name: 'Mariana Silva',
      age: 28,
      ntrpRating: 3.5,
      gender: Gender.female,
      profession: 'Médica',
      city: 'Campinas',
      state: 'SP',
      playStyle: PlayStyle.both,
      latitude: -23.184,
      longitude: -46.887,
      distanceKm: 0.8,
    ),
    const Player(
      id: 4,
      name: 'Pedro Almeida',
      age: 42,
      ntrpRating: 2.0,
      playStyle: PlayStyle.doubles,
      latitude: -23.191,
      longitude: -46.879,
      distanceKm: 2.1,
    ),
    const Player(
      id: 5,
      name: 'Camila Rocha',
      age: 31,
      ntrpRating: 3.0,
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
    ];
  }

  static List<Challenge> challenges({ChallengeListRole role = ChallengeListRole.created}) {
    final me = Player(id: currentUserId, name: 'Você', latitude: centerLat, longitude: centerLng, ntrpRating: 3.5);
    final opponent = players[0];
    final place = places[0];

    final direct = Challenge(
      id: 101,
      type: ChallengeType.direct,
      format: ChallengeFormat.singles,
      status: ChallengeStatus.pendingAcceptance,
      scheduledStart: DateTime.now().add(const Duration(days: 1)),
      creator: me,
      place: place,
      participants: [
        ChallengeParticipant(id: 1, role: 'creator', status: 'accepted', user: me),
        ChallengeParticipant(id: 2, role: 'invitee', status: 'pending', user: opponent),
      ],
      role: 'created',
    );

    final received = Challenge(
      id: 102,
      type: ChallengeType.direct,
      format: ChallengeFormat.singles,
      status: ChallengeStatus.pendingAcceptance,
      scheduledStart: DateTime.now().add(const Duration(days: 2)),
      creator: players[1],
      place: places[1],
      participants: [
        ChallengeParticipant(id: 3, role: 'creator', status: 'accepted', user: players[1]),
        ChallengeParticipant(id: 4, role: 'invitee', status: 'pending', user: me),
      ],
      role: 'received',
    );

    final publicChallenge = Challenge(
      id: 103,
      type: ChallengeType.public,
      format: ChallengeFormat.doubles,
      status: ChallengeStatus.pendingCandidates,
      scheduledStart: DateTime.now().add(const Duration(days: 3)),
      creator: players[2],
      place: place,
      minNtrp: 3.0,
      maxNtrp: 4.0,
      candidatesCount: 2,
      role: 'public_nearby',
    );

    return switch (role) {
      ChallengeListRole.created => [direct],
      ChallengeListRole.received => [received],
      ChallengeListRole.publicNearby => [publicChallenge],
    };
  }
}
