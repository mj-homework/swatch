/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

/// Single source of truth for the wide (side-by-side / landscape) layout decision.
class LayoutService {
  const LayoutService._();

  static bool isWide(double width) => width >= 720.0;
  static bool isNarrow(double width) => !isWide(width);
}
