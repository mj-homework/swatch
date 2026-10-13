/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/app/app.dart';
import 'package:swatch/app/app_dependencies.dart';

void main() {
  // AppDependencies creates the audio players, which need platform channels.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SwatchApp(dependencies: AppDependencies()));
}
