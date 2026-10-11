import 'dart:async';
import 'package:swatch/features/shopwatch/services/sound_player.dart';
import 'package:swatch/features/shopwatch/data/leaderboard_repository.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';

class FakeSound implements SoundPlayer {
  int plays = 0, disposals = 0;
  final scanAccuracies = <Accuracy>[];
  @override
  Future<void> playCheckoutBeep() async { plays++; }
  @override
  Future<void> playScan(Accuracy accuracy) async { scanAccuracies.add(accuracy); }
  @override
  Future<void> dispose() async { disposals++; }
}
class FakeRepository implements LeaderboardRepository {
  final requests = <String, Completer<NicknameStatus>>{};
  NicknameStatus reservation = NicknameStatus.available;
  int checks = 0, reservations = 0, submissions = 0;
  @override
  Future<NicknameStatus> check(String nickname) { checks++; return (requests[nickname] = Completer()).future; }
  @override
  Future<NicknameStatus> reserve(String nickname) async { reservations++; return reservation; }
  @override
  Future<bool> submit(GameRound round) async { submissions++; return true; }
  @override
  Future<List<LeaderboardEntry>?> top(int itemCount, Difficulty difficulty) async => [];
}
