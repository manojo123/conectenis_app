import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/shared/models/conversation.dart';
import 'package:conectenis_app/shared/models/court.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/models/match_record.dart';
import 'package:conectenis_app/shared/models/message.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

class MockApiService {
  final Map<int, List<Message>> _messages = {};
  final List<Conversation> _conversations = [];
  final List<MatchRecord> _matches = [];
  int _messageId = 100;
  int _conversationId = 1;
  int _matchId = 1;

  Future<List<Player>> nearbyPlayers({
    double? lat,
    double? lng,
    SkillLevel? skill,
    int? minAge,
    int? maxAge,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    var list = List<Player>.from(MockData.players);
    if (skill != null) {
      list = list.where((p) => p.skillLevel == skill).toList();
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

  Future<List<Court>> courts({double? lat, double? lng}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Court>.from(MockData.courts);
  }

  Future<Court?> courtById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      return MockData.courts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Conversation>> conversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<Conversation>.from(_conversations);
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
