import 'package:conectenis_app/features/chat/data/delete_message_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/shared/models/challenge.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/place.dart';
import 'package:conectenis_app/shared/models/play_invitation.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/match_record.dart';
import 'package:conectenis_app/shared/models/message.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

class MockApiService {
  final Map<int, List<Message>> _messages = {};
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
    Gender? gender,
    double? minNtrp,
    double? maxNtrp,
    int? minAge,
    int? maxAge,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    var list = List<Player>.from(MockData.players);
    if (name != null && name.isNotEmpty) {
      final query = name.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(query)).toList();
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
    return list;
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
    return _challenges.firstWhere(
      (c) => c.id == id,
      orElse: () => MockData.challenges().firstWhere((c) => c.id == id, orElse: () => MockData.challenges().first),
    );
  }

  Future<Challenge> createDirectChallenge({
    required ChallengeFormat format,
    required List<int> participantIds,
    required int placeId,
    required DateTime scheduledStart,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final me = Player(id: MockData.currentUserId, name: 'Você', latitude: MockData.centerLat, longitude: MockData.centerLng);
    final challenge = Challenge(
      id: 200 + _challenges.length,
      type: ChallengeType.direct,
      format: format,
      status: ChallengeStatus.pendingAcceptance,
      scheduledStart: scheduledStart,
      creator: me,
      place: _places.firstWhere((p) => p.id == placeId, orElse: () => _places.first),
      role: 'created',
    );
    _challenges = [challenge, ..._challenges];
    return challenge;
  }

  Future<Challenge> createPublicChallenge({
    required ChallengeFormat format,
    required DateTime scheduledStart,
    int? placeId,
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
}

final mockApiServiceProvider = Provider<MockApiService>((ref) => MockApiService());
