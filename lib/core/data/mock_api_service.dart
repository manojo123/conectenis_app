import 'package:conectenis_app/features/home/models/dashboard_matchmaking.dart';
import 'package:conectenis_app/features/home/models/dashboard_stats.dart';
import 'package:conectenis_app/features/chat/data/delete_message_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/core/network/api_exception.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/challenge_result.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/nearby_court.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/play_invitation.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/match_record.dart';
import 'package:conectenis_app/shared/models/message.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/models/chat_timeline_entry.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

class MockApiService {
  final Map<int, List<Message>> _messages = {};
  final Map<int, List<ChatChallengeEvent>> _challengeEventsByConversation = {};
  final List<Conversation> _conversations = [];
  final Set<int> _hiddenConversationIds = {};
  final Set<int> _hiddenMessageIdsForMe = {};
  final Set<int> _deletedForAllMessageIds = {};
  final List<MatchRecord> _matches = [];
  int _messageId = 100;
  int _conversationId = 1;
  int _matchId = 1;
  int _placeId = 100;
  final List<Place> _places = List.from(MockData.places);
  final List<PlayInvitation> _invitations = MockData.playInvitations();

  Future<List<Player>> nearbyPlayers({
    double? lat,
    double? lng,
    String? name,
    String? city,
    Gender? gender,
    double? minNtrp,
    double? maxNtrp,
    int? minAge,
    int? maxAge,
    String sort = 'distance',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    var list = List<Player>.from(MockData.players);
    if (name != null && name.isNotEmpty) {
      final query = name.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(query)).toList();
    }
    if (city != null && city.isNotEmpty) {
      final q = city.toLowerCase();
      list = list.where((p) => (p.city ?? '').toLowerCase().contains(q)).toList();
    }
    if (gender != null) {
      list = list.where((p) => p.gender == gender).toList();
    }
    if (minNtrp != null) {
      list = list.where((p) => p.ntrpRating >= minNtrp).toList();
    }
    if (maxNtrp != null) {
      list = list.where((p) => p.ntrpRating <= maxNtrp).toList();
    }
    if (minAge != null) {
      list = list.where((p) => (p.age ?? 0) >= minAge).toList();
    }
    if (maxAge != null) {
      list = list.where((p) => (p.age ?? 99) <= maxAge).toList();
    }
    switch (sort) {
      case 'ntrp_desc':
        list.sort((a, b) => b.ntrpRating.compareTo(a.ntrpRating));
      case 'age_asc':
        list.sort((a, b) => (a.age ?? 99).compareTo(b.age ?? 99));
      default:
        list.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    }
    return list;
  }

  Future<List<NearbyCourt>> nearbyCourts({double? lat, double? lng}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final appCourts = _places.map(
      (p) => NearbyCourt(
        name: p.name,
        latitude: p.latitude,
        longitude: p.longitude,
        distanceKm: p.distanceKm,
        placeId: p.id,
        source: 'app',
      ),
    );
    const googleCourts = [
      NearbyCourt(
        name: 'Arena Tennis Google',
        address: 'Av. Brasil, 1000 — Jundiaí',
        latitude: -23.187,
        longitude: -46.883,
        distanceKm: 1.8,
        googlePlaceId: 'ChIJ_mock_google_court_1',
        source: 'google',
      ),
    ];
    return [...appCourts, ...googleCourts];
  }

  Future<Player?> playerById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      return MockData.players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Place>> places({double? lat, double? lng, String? name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    var list = List<Place>.from(_places);
    if (name != null && name.trim().isNotEmpty) {
      final q = name.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<Place?> placeById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      final place = _places.firstWhere((p) => p.id == id);
      final reviews = _placeReviews[id] ?? place.recentReviews;
      if (reviews == place.recentReviews) return place;
      return Place(
        id: place.id,
        name: place.name,
        latitude: place.latitude,
        longitude: place.longitude,
        createdByUserId: place.createdByUserId,
        averageRating: place.averageRating,
        ratingsCount: place.ratingsCount,
        distanceKm: place.distanceKm,
        recentReviews: reviews,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Place> createPlace({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final place = Place(
      id: _placeId++,
      name: name,
      latitude: latitude,
      longitude: longitude,
      createdByUserId: MockData.currentUserId,
    );
    _places.add(place);
    return place;
  }

  Future<Place> updatePlace({
    required int id,
    String? name,
    double? latitude,
    double? longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _places.indexWhere((p) => p.id == id);
    if (idx < 0) throw StateError('Place not found');
    final old = _places[idx];
    final updated = Place(
      id: old.id,
      name: name ?? old.name,
      latitude: latitude ?? old.latitude,
      longitude: longitude ?? old.longitude,
      createdByUserId: old.createdByUserId,
      averageRating: old.averageRating,
      ratingsCount: old.ratingsCount,
      distanceKm: old.distanceKm,
    );
    _places[idx] = updated;
    return updated;
  }

  final Map<int, List<PlaceReview>> _placeReviews = {};

  Future<String> ratePlace({
    required int id,
    required int stars,
    String? comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _places.indexWhere((p) => p.id == id);
    if (idx < 0) return 'Avaliação salva.';
    final old = _places[idx];
    final reviews = List<PlaceReview>.from(_placeReviews[id] ?? []);
    reviews.insert(
      0,
      PlaceReview(author: 'Você', comment: comment ?? '', stars: stars),
    );
    _placeReviews[id] = reviews;
    final count = old.ratingsCount + 1;
    final avg = reviews.isEmpty
        ? stars.toDouble()
        : reviews.map((r) => r.stars).reduce((a, b) => a + b) / reviews.length;
    _places[idx] = Place(
      id: old.id,
      name: old.name,
      latitude: old.latitude,
      longitude: old.longitude,
      createdByUserId: old.createdByUserId,
      averageRating: avg,
      ratingsCount: count,
      distanceKm: old.distanceKm,
      recentReviews: reviews.take(10).toList(),
    );
    return 'Avaliação salva.';
  }

  Future<List<PlayInvitation>> playInvitations({InvitationListRole role = InvitationListRole.all}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return switch (role) {
      InvitationListRole.sent => _invitations.where((i) => i.role == 'sent').toList(),
      InvitationListRole.received => _invitations.where((i) => i.role == 'received').toList(),
      _ => List<PlayInvitation>.from(_invitations),
    };
  }

  Future<PlayInvitation> playInvitationById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _invitations.firstWhere((i) => i.id == id);
  }

  Future<PlayInvitation> createPlayInvitation({
    required int inviteeId,
    required int placeId,
    required DateTime scheduledAt,
    String? message,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final invitee = MockData.players.firstWhere((p) => p.id == inviteeId);
    final place = _places.firstWhere((p) => p.id == placeId);
    final inv = PlayInvitation(
      id: _invitations.length + 10,
      status: PlayInvitationStatus.pending,
      scheduledAt: scheduledAt,
      message: message,
      inviter: Player(
        id: MockData.currentUserId,
        name: 'Você',
        latitude: MockData.centerLat,
        longitude: MockData.centerLng,
      ),
      invitee: invitee,
      place: place,
      role: 'sent',
    );
    _invitations.insert(0, inv);
    return inv;
  }

  Future<PlayInvitation> playInvitationAction(int id, String action) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _invitations.indexWhere((i) => i.id == id);
    if (idx < 0) throw StateError('Invitation not found');
    final old = _invitations[idx];
    final status = switch (action) {
      'accept' => PlayInvitationStatus.accepted,
      'decline' => PlayInvitationStatus.declined,
      'cancel' => PlayInvitationStatus.cancelled,
      'complete' => PlayInvitationStatus.completed,
      _ => old.status,
    };
    final updated = PlayInvitation(
      id: old.id,
      status: status,
      scheduledAt: old.scheduledAt,
      message: old.message,
      completedAt: action == 'complete' ? DateTime.now() : old.completedAt,
      completedByUserId: action == 'complete' ? MockData.currentUserId : old.completedByUserId,
      inviter: old.inviter,
      invitee: old.invitee,
      place: old.place,
      role: old.role,
      hasRatedOpponent: old.hasRatedOpponent,
    );
    _invitations[idx] = updated;
    return updated;
  }

  Future<List<Conversation>> conversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _conversations.where((c) => !_hiddenConversationIds.contains(c.id)).toList();
  }

  Future<Conversation> startConversation(int otherUserId, String otherName) async {
    final existing = _conversations.where((c) => c.otherUserId == otherUserId);
    if (existing.isNotEmpty) return existing.first;

    final conv = Conversation(
      id: _conversationId++,
      otherUserId: otherUserId,
      otherUserName: otherName,
      updatedAt: DateTime.now(),
    );
    _conversations.insert(0, conv);
    _messages[conv.id] = [];
    return conv;
  }

  Future<List<ChatChallengeEvent>> challengeEvents(int conversationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<ChatChallengeEvent>.from(
      _challengeEventsByConversation[conversationId] ?? const [],
    );
  }

  Future<List<Message>> messages(int conversationId, {int? currentUserId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final list = _messages[conversationId] ?? [];
    return list
        .where((m) =>
            !_deletedForAllMessageIds.contains(m.id) &&
            !_hiddenMessageIdsForMe.contains(m.id))
        .map((m) => m.copyWith(isMine: currentUserId != null && m.userId == currentUserId))
        .toList();
  }

  Future<Message> sendMessage({
    required int conversationId,
    required int userId,
    required String body,
  }) async {
    final msg = Message(
      id: _messageId++,
      conversationId: conversationId,
      userId: userId,
      body: body,
      createdAt: DateTime.now(),
      isMine: true,
    );
    _messages.putIfAbsent(conversationId, () => []).add(msg);
    _hiddenConversationIds.remove(conversationId);

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx >= 0) {
      final c = _conversations[idx];
      _conversations[idx] = Conversation(
        id: c.id,
        otherUserId: c.otherUserId,
        otherUserName: c.otherUserName,
        lastMessage: body,
        updatedAt: DateTime.now(),
        otherAvatarUrl: c.otherAvatarUrl,
      );
    }
    return msg;
  }

  Future<void> deleteConversation(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _hiddenConversationIds.add(id);
  }

  Future<void> deleteMessage(int id, {required DeleteMessageScope scope}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (scope == DeleteMessageScope.forEveryone) {
      _deletedForAllMessageIds.add(id);
    } else {
      _hiddenMessageIdsForMe.add(id);
    }
  }

  Future<List<MatchRecord>> matches() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<MatchRecord>.from(_matches);
  }

  Future<List<RivalStats>> rivals() async {
    final map = <int, RivalStats>{};
    for (final m in _matches) {
      final existing = map[m.opponentId];
      if (existing == null) {
        map[m.opponentId] = RivalStats(
          opponentId: m.opponentId,
          opponentName: m.opponentName,
          wins: m.won ? 1 : 0,
          losses: m.won ? 0 : 1,
        );
      } else {
        map[m.opponentId] = RivalStats(
          opponentId: existing.opponentId,
          opponentName: existing.opponentName,
          wins: existing.wins + (m.won ? 1 : 0),
          losses: existing.losses + (m.won ? 0 : 1),
        );
      }
    }
    return map.values.toList();
  }

  Future<MatchRecord> logMatch({
    required int opponentId,
    required String opponentName,
    required int playerScore,
    required int opponentScore,
    required bool won,
  }) async {
    final record = MatchRecord(
      id: _matchId++,
      opponentId: opponentId,
      opponentName: opponentName,
      playerScore: playerScore,
      opponentScore: opponentScore,
      won: won,
      playedAt: DateTime.now(),
    );
    _matches.insert(0, record);
    return record;
  }

  List<Challenge> _challenges = MockData.challenges();

  Future<List<Challenge>> challenges({required ChallengeListRole role}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final seed = MockData.challenges(role: role);
    final extra = _challenges.where((c) {
      if (role == ChallengeListRole.created) return c.role == 'created';
      if (role == ChallengeListRole.received) return c.role == 'received';
      return true;
    });
    final ids = <int>{};
    final merged = <Challenge>[];
    for (final c in [...extra, ...seed]) {
      if (ids.add(c.id)) merged.add(c);
    }
    return merged;
  }

  Future<Challenge> challengeById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final challenge = _challenges.firstWhere(
      (c) => c.id == id,
      orElse: () => MockData.challenges().firstWhere((c) => c.id == id, orElse: () => MockData.challenges().first),
    );
    return _enrichChallengeForCurrentUser(challenge);
  }

  Challenge _enrichChallengeForCurrentUser(Challenge challenge) {
    final userId = MockData.currentUserId;
    final canSubmit = (challenge.status == ChallengeStatus.accepted ||
            challenge.status == ChallengeStatus.pendingScore) &&
        challenge.result == null;
    final canApprove = challenge.status == ChallengeStatus.pendingResultApproval &&
        challenge.result != null &&
        !challenge.hasUserApprovedResult(userId);
    return Challenge(
      id: challenge.id,
      type: challenge.type,
      format: challenge.format,
      status: challenge.status,
      scheduledStart: challenge.scheduledStart,
      scheduledEnd: challenge.scheduledEnd,
      message: challenge.message,
      openLocation: challenge.openLocation,
      minNtrp: challenge.minNtrp,
      maxNtrp: challenge.maxNtrp,
      genderPreference: challenge.genderPreference,
      slotsTotal: challenge.slotsTotal,
      creator: challenge.creator,
      place: challenge.place,
      participants: challenge.participants,
      candidatesCount: challenge.candidatesCount,
      role: challenge.role,
      hasSubmittedEvaluation: challenge.hasSubmittedEvaluation,
      result: challenge.result,
      canSubmitResult: canSubmit,
      canApproveResult: canApprove,
    );
  }

  Future<Challenge> createDirectChallenge({
    required ChallengeFormat format,
    required List<int> participantIds,
    int? placeId,
    String? googlePlaceId,
    required DateTime scheduledStart,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final me = Player(id: MockData.currentUserId, name: 'Você', latitude: MockData.centerLat, longitude: MockData.centerLng);
    final opponents = participantIds.map((id) {
      try {
        return MockData.players.firstWhere((p) => p.id == id);
      } catch (_) {
        return Player(id: id, name: 'Jogador $id', latitude: MockData.centerLat, longitude: MockData.centerLng);
      }
    }).toList();
    Place? place;
    if (placeId != null) {
      place = _places.firstWhere((p) => p.id == placeId, orElse: () => _places.first);
    } else if (googlePlaceId != null) {
      place = Place(
        id: 0,
        name: 'Quadra Google',
        latitude: MockData.centerLat,
        longitude: MockData.centerLng,
        createdByUserId: 0,
      );
    }
    final challenge = Challenge(
      id: 200 + _challenges.length,
      type: ChallengeType.direct,
      format: format,
      status: ChallengeStatus.pendingAcceptance,
      scheduledStart: scheduledStart,
      creator: me,
      creatorTeam: 1,
      place: place,
      participants: opponents
          .map(
            (p) => ChallengeParticipant(
              id: p.id,
              role: 'participant',
              status: 'pending',
              user: p,
              team: 2,
            ),
          )
          .toList(),
      role: 'created',
    );
    _challenges = [challenge, ..._challenges];
    await _attachChallengeToConversations(challenge, participantIds);
    return challenge;
  }

  Future<void> _attachChallengeToConversations(
    Challenge challenge,
    List<int> participantIds,
  ) async {
    final event = ChatChallengeEvent(
      challengeId: challenge.id,
      status: challenge.status,
      createdAt: DateTime.now(),
      summary: 'Desafio de tênis · ${challenge.status.label}',
    );
    for (final pid in participantIds) {
      String name;
      try {
        name = MockData.players.firstWhere((p) => p.id == pid).name;
      } catch (_) {
        name = 'Jogador';
      }
      final conv = await startConversation(pid, name);
      final list = _challengeEventsByConversation.putIfAbsent(conv.id, () => []);
      if (!list.any((e) => e.challengeId == challenge.id)) {
        list.add(event);
      }
    }
  }

  Future<Challenge> createPublicChallenge({
    required ChallengeFormat format,
    required DateTime scheduledStart,
    int? placeId,
    String? googlePlaceId,
    bool openLocation = false,
    double? minNtrp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final me = Player(id: MockData.currentUserId, name: 'Você', latitude: MockData.centerLat, longitude: MockData.centerLng);
    Place? place;
    if (placeId != null) {
      for (final p in _places) {
        if (p.id == placeId) {
          place = p;
          break;
        }
      }
    } else if (googlePlaceId != null) {
      place = Place(
        id: 0,
        name: 'Quadra Google',
        latitude: MockData.centerLat,
        longitude: MockData.centerLng,
        createdByUserId: 0,
      );
    }
    final challenge = Challenge(
      id: 300 + _challenges.length,
      type: ChallengeType.public,
      format: format,
      status: ChallengeStatus.pendingCandidates,
      scheduledStart: scheduledStart,
      creator: me,
      place: place,
      openLocation: openLocation,
      minNtrp: minNtrp,
      role: 'created',
    );
    _challenges = [challenge, ..._challenges];
    return challenge;
  }

  Future<Challenge> submitChallengeEvaluation(
    int id, {
    required ChallengeFormat format,
    required bool skipScore,
    int? myGamesWon,
    int? opponentGamesWon,
    int? winnerUserId,
    List<int>? winnerTeam,
    List<OpponentRatingPayload>? opponentRatings,
    int? opponentPunctualityStars,
    String? opponentComment,
    int? placeQualityStars,
    String? placeComment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx < 0) return challengeById(id);
    final old = _challenges[idx];
    if (old.result != null) {
      throw ApiException(
        'O resultado já foi informado por outro participante.',
        statusCode: 409,
      );
    }

    final isDoubles = format == ChallengeFormat.doubles;
    String? winnerName;
    String? winnerTeamLabel;
    if (!skipScore) {
      if (isDoubles && winnerTeam != null && winnerTeam.length == 2) {
        winnerTeamLabel = winnerTeam.map((uid) => old.participantName(uid)).whereType<String>().join(' / ');
      } else {
        winnerName = winnerUserId == null ? null : old.participantName(winnerUserId);
      }
    }
    final scoreLabel = skipScore
        ? null
        : '${myGamesWon ?? 0} × ${opponentGamesWon ?? 0}';

    final approvals = old.participantUserIds.map((uid) {
      final approved = uid == MockData.currentUserId;
      return ChallengeResultApproval(
        userId: uid,
        userName: old.participantName(uid) ?? 'Jogador',
        approved: approved,
        approvedAt: approved ? DateTime.now() : null,
      );
    }).toList();

    final ratings = opponentRatings
            ?.map(
              (r) => OpponentResultRating(
                userId: r.userId,
                userName: old.participantName(r.userId) ?? 'Jogador',
                punctualityStars: r.punctualityStars,
                comment: r.comment,
              ),
            )
            .toList() ??
        const [];

    final result = ChallengeResult(
      skipScore: skipScore,
      winnerUserId: isDoubles ? null : winnerUserId,
      winnerTeamIds: winnerTeam ?? const [],
      winnerName: winnerName,
      winnerTeamLabel: winnerTeamLabel,
      scoreLabel: scoreLabel,
      submittedByUserId: MockData.currentUserId,
      submittedByName: 'Você',
      myGamesWon: myGamesWon,
      opponentGamesWon: opponentGamesWon,
      approvals: approvals,
      opponentPunctualityStars: opponentPunctualityStars,
      opponentComment: opponentComment,
      opponentRatings: ratings,
      placeQualityStars: placeQualityStars,
      placeComment: placeComment,
    );

    final updated = Challenge(
      id: old.id,
      type: old.type,
      format: old.format,
      status: ChallengeStatus.pendingResultApproval,
      scheduledStart: old.scheduledStart,
      scheduledEnd: old.scheduledEnd,
      message: old.message,
      openLocation: old.openLocation,
      minNtrp: old.minNtrp,
      maxNtrp: old.maxNtrp,
      genderPreference: old.genderPreference,
      slotsTotal: old.slotsTotal,
      creator: old.creator,
      creatorTeam: old.creatorTeam,
      place: old.place,
      participants: old.participants,
      candidatesCount: old.candidatesCount,
      role: old.role,
      hasSubmittedEvaluation: true,
      result: result,
    );
    _challenges[idx] = updated;
    return _enrichChallengeForCurrentUser(updated);
  }

  Future<Challenge> approveChallengeResult(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx < 0) return challengeById(id);
    final old = _challenges[idx];
    final result = old.result;
    if (result == null || old.status != ChallengeStatus.pendingResultApproval) {
      return _enrichChallengeForCurrentUser(old);
    }

    final userId = MockData.currentUserId;
    final approvals = result.approvals.map((a) {
      if (a.userId == userId) {
        return ChallengeResultApproval(
          userId: a.userId,
          userName: a.userName,
          approved: true,
          approvedAt: DateTime.now(),
        );
      }
      return a;
    }).toList();

    final allApproved = old.participantUserIds.every(
      (uid) => approvals.any((a) => a.userId == uid && a.approved),
    );

    final newResult = ChallengeResult(
      skipScore: result.skipScore,
      winnerUserId: result.winnerUserId,
      winnerName: result.winnerName,
      scoreLabel: result.scoreLabel,
      submittedByUserId: result.submittedByUserId,
      submittedByName: result.submittedByName,
      myGamesWon: result.myGamesWon,
      opponentGamesWon: result.opponentGamesWon,
      approvals: approvals,
      opponentPunctualityStars: result.opponentPunctualityStars,
      opponentComment: result.opponentComment,
      placeQualityStars: result.placeQualityStars,
      placeComment: result.placeComment,
    );

    final updated = Challenge(
      id: old.id,
      type: old.type,
      format: old.format,
      status: allApproved ? ChallengeStatus.completed : ChallengeStatus.pendingResultApproval,
      scheduledStart: old.scheduledStart,
      scheduledEnd: old.scheduledEnd,
      message: old.message,
      openLocation: old.openLocation,
      minNtrp: old.minNtrp,
      maxNtrp: old.maxNtrp,
      genderPreference: old.genderPreference,
      slotsTotal: old.slotsTotal,
      creator: old.creator,
      place: old.place,
      participants: old.participants,
      candidatesCount: old.candidatesCount,
      role: old.role,
      hasSubmittedEvaluation: true,
      result: newResult,
    );
    _challenges[idx] = updated;
    return _enrichChallengeForCurrentUser(updated);
  }

  Future<Challenge> cancelChallenge(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx < 0) return challengeById(id);
    final old = _challenges[idx];
    final updated = Challenge(
      id: old.id,
      type: old.type,
      format: old.format,
      status: ChallengeStatus.cancelled,
      scheduledStart: old.scheduledStart,
      scheduledEnd: old.scheduledEnd,
      message: old.message,
      openLocation: old.openLocation,
      minNtrp: old.minNtrp,
      maxNtrp: old.maxNtrp,
      genderPreference: old.genderPreference,
      slotsTotal: old.slotsTotal,
      creator: old.creator,
      place: old.place,
      participants: old.participants,
      candidatesCount: old.candidatesCount,
      role: old.role,
      hasSubmittedEvaluation: old.hasSubmittedEvaluation,
      result: old.result,
    );
    _challenges[idx] = updated;
    return updated;
  }

  Future<UserProfile> registerMock({
    required String name,
    required String email,
    required String password,
  }) async {
    return UserProfile(
      id: 1,
      name: name,
      email: email,
      profileComplete: false,
    );
  }

  /// Mock matchmaking count: same NTRP as current user (3.5), filtered by radius.
  /// Radius 5 km returns zero matches to demo the viral share state.
  Future<DashboardMatchmaking> dashboardMatchmaking({required int radiusKm}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    const userNtrp = 3.5;
    if (radiusKm <= 5) {
      return DashboardMatchmaking(
        count: 0,
        radiusKm: radiusKm,
        ntrpRating: userNtrp,
        hasMatches: false,
      );
    }
    final count = MockData.players
        .where((p) =>
            p.ntrpRating == userNtrp &&
            (p.distanceKm ?? double.infinity) <= radiusKm)
        .length;
    return DashboardMatchmaking(
      count: count,
      radiusKm: radiusKm,
      ntrpRating: userNtrp,
      hasMatches: count > 0,
    );
  }

  Future<DashboardStats> dashboardStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return DashboardStats.fromJson(const {
      'tennis_level': {'ntrp_rating': 3.5},
      'record': {
        'wins': 8,
        'losses': 3,
        'matches_played': 11,
        'win_rate': 0.727,
      },
      'ranking': {
        'local': {
          'scope': 'home',
          'city_id': 1,
          'city_name': 'Jundiaí',
          'state': 'SP',
          'rank': 12,
          'total_players': 85,
          'points': 80,
        },
        'general': {
          'scope': 'played',
          'state': 'SP',
          'rank': 45,
          'total_players': 500,
          'points': 80,
        },
      },
    });
  }
}

final mockApiServiceProvider = Provider<MockApiService>((ref) => MockApiService());
