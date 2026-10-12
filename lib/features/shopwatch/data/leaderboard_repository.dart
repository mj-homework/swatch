/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import '../domain/game_config.dart';
import '../domain/game_round.dart';

enum NicknameStatus { checking, available, taken, offline, invalid }

class NicknamePolicy {
  const NicknamePolicy({this.blocked = const ['admin', 'fuck', 'shit']});
  final List<String> blocked;
  String normalize(String value) {
    var key = value.trim().toLowerCase();
    const groups = ['áàâäãå', 'éèêë', 'íìîï', 'óòôöõő', 'úùûüű', 'ç', 'ñ'];
    const replacements = ['a', 'e', 'i', 'o', 'u', 'c', 'n'];
    for (var i = 0; i < groups.length; i++) {
      for (final letter in groups[i].split('')) { key = key.replaceAll(letter, replacements[i]); }
    }
    return key.replaceAll(RegExp('[\u0300-\u036f]'), '');
  }
  bool isValid(String value) {
    final key = normalize(value);
    return RegExp(r'^[a-z0-9_]{3,16}$').hasMatch(key) &&
      !blocked.any((word) => key.contains(normalize(word)));
  }
}

class LeaderboardEntry {
  const LeaderboardEntry(this.nickname, this.averageDiffMs);
  final String nickname;
  final double averageDiffMs;
}

abstract interface class LeaderboardRepository {
  Future<NicknameStatus> check(String nickname);
  /// Available means ownership was successfully reserved, not just a hint.
  Future<NicknameStatus> reserve(String nickname);
  Future<bool> submit(GameRound round);
  /// null explicitly means offline, not an empty leaderboard.
  Future<List<LeaderboardEntry>?> top(int itemCount, Difficulty difficulty);
}

class OfflineLeaderboardRepository implements LeaderboardRepository {
  const OfflineLeaderboardRepository();
  @override
  Future<NicknameStatus> check(String nickname) async => NicknameStatus.offline;
  @override
  Future<NicknameStatus> reserve(String nickname) async => NicknameStatus.offline;
  @override
  Future<bool> submit(GameRound round) async => false;
  @override
  Future<List<LeaderboardEntry>?> top(int itemCount, Difficulty difficulty) async => null;
}
