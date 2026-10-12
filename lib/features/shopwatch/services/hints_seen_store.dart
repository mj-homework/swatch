// Copyright (c) 2026 Juhász Mátyás
// SPDX-License-Identifier: MIT

abstract interface class HintsSeenStore {
  Future<bool> isSeen();
  Future<void> markSeen();
}

class InMemoryHintsSeenStore implements HintsSeenStore {
  bool _seen = false;

  @override
  Future<bool> isSeen() async => _seen;

  @override
  Future<void> markSeen() async {
    _seen = true;
  }
}
