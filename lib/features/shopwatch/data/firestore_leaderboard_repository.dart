import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/game_config.dart';
import '../domain/game_round.dart';
import 'leaderboard_repository.dart';

class FirestoreLeaderboardRepository implements LeaderboardRepository {
  FirestoreLeaderboardRepository({required this.auth, required this.firestore,
    this.policy = const NicknamePolicy(), this.timeout = const Duration(seconds: 5)});
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final NicknamePolicy policy;
  final Duration timeout;
  Future<String> _uid() async => auth.currentUser?.uid ??
      (await auth.signInAnonymously().timeout(timeout)).user!.uid;
  @override
  Future<NicknameStatus> check(String nickname) async {
    if (!policy.isValid(nickname)) return NicknameStatus.invalid;
    try {
      final uid = await _uid();
      final doc = await firestore.collection('players').doc(policy.normalize(nickname))
          .get(const GetOptions(source: Source.server)).timeout(timeout);
      return !doc.exists || doc.data()?['uid'] == uid ? NicknameStatus.available : NicknameStatus.taken;
    } catch (_) { return NicknameStatus.offline; }
  }
  @override
  Future<NicknameStatus> reserve(String nickname) async {
    if (!policy.isValid(nickname)) return NicknameStatus.invalid;
    try {
      final uid = await _uid();
      final ref = firestore.collection('players').doc(policy.normalize(nickname));
      return await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(ref);
        if (doc.exists) return doc.data()?['uid'] == uid ? NicknameStatus.available : NicknameStatus.taken;
        transaction.set(ref, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
        return NicknameStatus.available;
      }).timeout(timeout);
    } catch (_) { return NicknameStatus.offline; }
  }
  @override
  Future<bool> submit(GameRound round) async {
    if (!round.ownedNickname || round.status != RoundStatus.finished) return false;
    try {
      final uid = await _uid();
      // Stable per round and owner; transaction makes retries idempotent.
      final ref = firestore.collection('scores').doc('${uid}_${round.id}');
      await firestore.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        if (existing.exists) return;
        transaction.set(ref, {
          'uid': uid, 'nickname': round.nickname,
          'normalizedNickname': policy.normalize(round.nickname),
          'totalDiffMs': round.totalError.inMilliseconds,
          'itemCount': round.items.length, 'difficulty': round.difficulty.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }).timeout(timeout);
      return true;
    } catch (_) { return false; }
  }
  @override
  Future<List<LeaderboardEntry>?> top(int itemCount, Difficulty difficulty) async {
    try {
      await _uid();
      final snapshot = await firestore.collection('scores')
        .where('itemCount', isEqualTo: itemCount).where('difficulty', isEqualTo: difficulty.name)
        .orderBy('totalDiffMs').limit(10).get(const GetOptions(source: Source.server)).timeout(timeout);
      return snapshot.docs.map((d) => LeaderboardEntry(d.data()['nickname'] as String,
          d.data()['totalDiffMs'] as int)).toList();
    } catch (_) { return null; }
  }
}
