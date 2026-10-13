/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:swatch/features/shopwatch/services/hints_seen_store.dart';
import 'package:swatch/core/services/sound_player.dart';

class FakeHintsSeenStore implements HintsSeenStore {
  FakeHintsSeenStore({this.seen = true});

  bool seen;
  int markSeenCalls = 0;

  @override
  Future<bool> isSeen() async => seen;

  @override
  Future<void> markSeen() async {
    markSeenCalls++;
    seen = true;
  }
}

class FakeSound implements SoundPlayer {
  int disposals = 0, tickingStarts = 0, tickingStops = 0;
  bool ticking = false;
  final cues = <SoundCue>[];
  List<SoundCue> get scanCues => cues.where((cue) => cue != SoundCue.checkoutBeep).toList();
  int get plays => cues.where((cue) => cue == SoundCue.checkoutBeep).length;

  @override
  Future<void> play(SoundCue cue) async {
    cues.add(cue);
  }

  @override
  Future<void> startTicking() async {
    tickingStarts++;
    ticking = true;
  }

  @override
  Future<void> stopTicking() async {
    tickingStops++;
    ticking = false;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    ticking = false;
  }
}
