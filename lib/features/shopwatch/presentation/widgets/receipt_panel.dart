/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/receipt_list.dart';

/// Scrollable receipt for the running round. Scrolls to the newest item as
/// items are added, and back to the top when the cart is emptied.
class ReceiptPanel extends StatefulWidget {
  const ReceiptPanel({
    super.key,
    required this.gameRound,
    required this.checkingOut,
    required this.onClear,
  });

  final ValueListenable<GameRound?> gameRound;
  final bool checkingOut;
  final VoidCallback onClear;

  @override
  State<ReceiptPanel> createState() => _ReceiptPanelState();
}

class _ReceiptPanelState extends State<ReceiptPanel> {
  final _scrollController = ScrollController();
  String? _lastRoundId;
  int _lastResultCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => ValueListenableBuilder<GameRound?>(
          valueListenable: widget.gameRound,
          builder: (_, round, __) {
            final resultCount = round?.results.length ?? 0;
            final resultsCleared = _lastResultCount > 0 && resultCount == 0;

            void scrollTo(double Function(ScrollPosition p) target) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_scrollController.hasClients) return;

                _scrollController.animateTo(
                  target(_scrollController.position),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }

            if (resultsCleared) {
              scrollTo((p) => p.minScrollExtent);
            } else if (round?.id == _lastRoundId && resultCount > _lastResultCount) {
              scrollTo((p) => p.maxScrollExtent);
            }

            _lastRoundId = round?.id;
            _lastResultCount = resultCount;

            return SingleChildScrollView(
              controller: _scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: round == null
                    ? const ReceiptList()
                    : ReceiptList(
                        showClear: round.results.isNotEmpty,
                        onClear: !widget.checkingOut && round.results.isNotEmpty ? widget.onClear : null,
                        round: round,
                        showTotal: round.status == RoundStatus.finished,
                      ),
              ),
            );
          },
        ),
      );
}
