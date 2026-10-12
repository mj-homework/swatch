/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/app/app.dart';
import 'package:swatch/features/shopwatch/data/firebase_bootstrap.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await initializeLeaderboard();
  runApp(SwatchApp(shopwatchDependencies: ShopwatchDependencies(repository: repository)));
}
