/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/shopwatch/data/firebase_bootstrap.dart';
import 'features/shopwatch/shopwatch_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await initializeLeaderboard();
  runApp(SwatchApp(shopwatchDependencies: ShopwatchDependencies(repository: repository)));
}
