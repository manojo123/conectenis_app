# Frontend work request — pending client implementation

> Paste this document into a Flutter/Claude Code session on this repo
> (`conectenis_app`). It is self-contained. Companion to
> `docs/BACKEND_PROMPT_REDESIGN.md` — the two items below are blocked on
> the backend contracts specified there (§10 and §12); the third is
> independent and can proceed any time.

## Context

QA testing surfaced two features that need coordinated backend+client
work. The backend spec is finalized in `docs/BACKEND_PROMPT_REDESIGN.md`
§10 (doubles group chat) and §12 (multi-set match scoring). **Do not
start either until backend confirms the corresponding contract is live**
— shipping either side alone breaks production (score submission, or
conversations list parsing).

---

## 1. Doubles group chat (blocked on backend §10)

### Preconditions
Confirm with backend that `GET /api/conversations` returns `type: "group"`
rows with `challenge_id`, `title`, `participants`, `is_archived` per the
spec before starting.

### Model changes
`lib/shared/models/conversation.dart` — add:
- `type` (`'direct' | 'group'`, default `'direct'` when absent)
- `challengeId` (`int?`)
- `title` (`String?`, group rows only)
- `participants` (`List<ConversationParticipant>`, new small model:
  `{id, name, avatarUrl}`)
- `isArchived` (`bool`, default `false`)

Keep `otherUserId`/`otherUserName`/`otherAvatarUrl` as-is for `direct`
rows (unchanged code path) — they're simply absent/null on `group` rows.

### Chat list (`lib/features/chat/presentation/chat_list_screen.dart`)
- `_conversationCard`: branch on `c.type == 'group'` — render an avatar
  stack (2-3 overlapping `UserAvatar`s from `participants`, +N badge if
  more) instead of a single avatar, and `c.title` instead of
  `c.otherUserName`.
- `_previewText`: for group rows, prefix with the sender's name from
  `participants` (never "Você" vs a single other name — look up by id).
- If `c.isArchived`, dim the row slightly and suppress the unread badge
  (archived threads shouldn't need attention).

### Chat thread (`lib/features/chat/presentation/chat_thread_screen.dart`)
- Header: for `type: group`, show `title` + participant count instead of
  a single peer name/avatar; tapping the header could open a simple
  participants list (bottom sheet) instead of `_openProfile`.
- Bubbles (`_bubble`): group threads need a sender name label above each
  non-mine bubble (look up `m.userId` in the conversation's
  `participants`) — today's mine/theirs-only styling assumes exactly 2
  people.
- Composer: if `isArchived`, replace the input row with a disabled state
  ("Este chat foi encerrado" or similar) — don't call `send()` at all.
- `markRead`/polling logic is unchanged — it's keyed by conversation id
  regardless of type.

### Repository (`lib/features/chat/data/chat_repository.dart`)
No new methods needed — `conversations()`, `timeline()`, `send()`,
`markRead()` all work by conversation id already. Just make sure
`Conversation.fromJson` parses the new fields defensively (null-safe,
matching the existing pattern for `unreadCount`/`lastMessageSenderId`).

### Notifications
If backend sends a `group_chat_started` notification type (§10), add it
to whatever notification-type → icon/label mapping exists in the
Notificações tab, and make tapping it deep-link to
`/messages/{conversationId}`.

---

## 2. Multi-set match scoring (blocked on backend §12)

### Preconditions
Confirm with backend that challenge creation accepts `scoring_format`,
and the evaluation submit endpoint accepts the new `sets`/`super_tiebreak`
shape, per the spec, before starting. This is the larger of the two —
read `docs/BACKEND_PROMPT_REDESIGN.md` §12 in full first.

### New enum (`lib/shared/models/enums.dart`)
Add `ScoringFormat`, mirroring the existing `ChallengeFormat` pattern:
```dart
enum ScoringFormat {
  proSet9('pro_set_9', 'Set único (9 games, super tiebreak em 8-8)'),
  twoSetsSuperTiebreak('two_sets_super_tiebreak', '2 sets com super tiebreak'),
  bestOfThreeSets('best_of_three_sets', 'Melhor de 3 sets');

  const ScoringFormat(this.value, this.label);
  final String value;
  final String label;

  static ScoringFormat fromValue(String? value) => ScoringFormat.values.firstWhere(
        (e) => e.value == value,
        orElse: () => ScoringFormat.bestOfThreeSets,
      );
}
```

### Challenge creation (`lib/features/challenges/presentation/new_challenge_screen.dart`)
Add a `ScoringFormat` selector (segmented/radio, 3 options with the pt-BR
labels above) alongside the existing Formato (singles/doubles) picker.
Default to `bestOfThreeSets`. Send as `scoring_format` in the create
payload; add `scoringFormat` to the `Challenge` model
(`lib/shared/models/challenge.dart`) parsed from the response.

### Result model (`lib/shared/models/challenge_result.dart`)
Replace `myGamesWon`/`opponentGamesWon` with:
- `sets`: `List<SetScore>` — new small model `{myGames, opponentGames,
  tiebreak: TiebreakScore?}`
- `superTiebreak`: `TiebreakScore?`
- `TiebreakScore`: `{myPoints, opponentPoints}`

Keep `scoreLabel` as-is (backend computes the display string — e.g.
`"6-4, 7-6(3)"` or `"9-8(10-5)"` — the client just displays it, doesn't
reformat it).

### Evaluation screen (`lib/features/challenges/presentation/challenge_evaluation_screen.dart`)
This needs the biggest rework. Read `challenge.scoringFormat` and render:
- **`proSet9`**: one set-entry row, games capped conceptually at 9; if
  both fields are `8`, reveal a tiebreak points row (my/opponent) — this
  *is* the match-deciding `super_tiebreak`, not a per-set tiebreak.
- **`twoSetsSuperTiebreak`**: exactly 2 set-entry rows; if each has its
  own 6-6 tiebreak, show a per-set tiebreak points row for that set; if
  the two sets split (1 each), reveal a separate "Super tiebreak (se
  empatar)" points row that becomes required.
- **`bestOfThreeSets`**: 2 set-entry rows always visible; a 3rd appears
  only once the first two split 1-1 (mirror the existing conditional
  "Empate → quem venceu" pattern already in this file, just per-set
  instead of a single flag); each set gets its own 6-6 tiebreak row when
  triggered.
- Winner computation (today's inline logic comparing `myGames`/
  `opponentGames`) needs to become "count sets won by games (using the
  tiebreak to break a 6-6 tie), plus the super tiebreak as the decider
  where applicable" — write this as a pure function you can unit test
  (e.g. `lib/shared/utils/match_score.dart`) rather than inline in the
  widget, since the branching per format is non-trivial and worth
  covering with a test file (`test/match_score_test.dart`) given three
  distinct rule sets.
- Submit payload: build the `sets`/`super_tiebreak` JSON per §12's shape
  and pass through `ChallengesRepository.submitEvaluation` (update its
  signature to take `List<SetScore>` + `TiebreakScore?` instead of the
  two flat ints).

### Approval screen (`lib/features/challenges/presentation/challenge_approve_evaluation_screen.dart`)
Render the submitted `sets`/`superTiebreak` for the approver to review
(e.g. "Set 1: 6-4 · Set 2: 6-7 (tiebreak 5-7) · Super tiebreak: 10-8") —
this screen only displays, doesn't re-derive the winner (trust what was
submitted, consistent with today's approve/reject-only flow).

### Anywhere `scoreLabel` is already displayed
Mural cards, challenge detail, history — these already just render the
`scoreLabel` string from `ChallengeResult`, so they likely need no change
beyond the model field rename. Verify each call site after the model
change (compile errors will find them).

---

## 3. Reverb real-time upgrade (independent — not blocked, can start now)

Currently `lib/features/chat/services/reverb_service.dart` ignores
`REVERB_HOST`/`PORT`/`SCHEME` because `pusher_channels_flutter` 2.4.x
can't target a custom websocket host, so Reverb stays disabled
(`REVERB_APP_KEY` empty in `.env`) and chat relies on the polling stopgap
(`chat_list_screen.dart`/`chat_thread_screen.dart`, ~12s/~5s timers).

To enable real push:
1. Bump `pusher_channels_flutter` to `^2.6.0` in `pubspec.yaml`.
2. This forces a `flutter_secure_storage` bump to `10.x` (see the
   existing comment in `pubspec.yaml` above the pusher dependency) —
   check `flutter_secure_storage_linux`/`_macos`/`_windows`/`_web`
   transitive versions resolve cleanly; run `flutter pub get` and fix any
   conflicts.
3. In `reverb_service.dart`, pass `host: Env.reverbHost`,
   `wsPort`/`wssPort: Env.reverbPort` into `_pusher!.init(...)` (currently
   only `apiKey`/`cluster`/`useTLS` are passed — host/port are silently
   dropped today).
4. Once confirmed working end-to-end against the backend's Reverb server
   (already documented as ready server-side in
   `docs/BACKEND_PROMPT_REDESIGN.md` §8), decide whether to keep the
   polling timers as a failover or remove them — recommend keeping a
   longer failover poll (e.g. 30-60s) rather than none, in case a socket
   silently drops.
5. Set `REVERB_APP_KEY` (and host/port/scheme) in `.env` to actually turn
   it on — currently empty on purpose.

---

## Verification checklist (per item, before marking done)

1. `flutter analyze --no-pub` clean, `flutter test` green (add tests for
   `match_score.dart` given §2's three rule sets).
2. Manual pass against the live API: group chat — create a doubles
   challenge, get all 4 confirmed, confirm the thread appears for all 4,
   send messages, complete the challenge, confirm it goes read-only.
   Scoring — submit a match in each of the 3 formats including a
   tiebreak/super-tiebreak path, confirm the approval screen and mural
   card render the resulting `score_label` correctly.
3. Light + dark theme sweep on any new UI (avatar stacks, set-entry
   rows, tiebreak inputs).
