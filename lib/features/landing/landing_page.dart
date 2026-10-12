/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import '../../app/router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final stopwatch = _FeatureButton(
              icon: Icons.timer_outlined,
              label: 'Stopwatch',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.stopwatch),
              primary: true,
            );
            final shopwatch = _FeatureButton(
              icon: Icons.shopping_cart_outlined,
              label: 'Shopwatch',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.shopwatch),
            );

            return Padding(
              padding: const EdgeInsets.all(24),
              child: landscape
                  ? Row(
                      children: _buildFeatureChildren(
                        stopwatch: stopwatch,
                        shopwatch: shopwatch,
                        landscape: true,
                      ),
                    )
                  : Column(
                      children: _buildFeatureChildren(
                        stopwatch: stopwatch,
                        shopwatch: shopwatch,
                        landscape: false,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

List<Widget> _buildFeatureChildren({
  required Widget stopwatch,
  required Widget shopwatch,
  required bool landscape,
}) {
  Widget squareButton(Widget button) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: AspectRatio(aspectRatio: 1, child: button),
          ),
        ),
      );

  return [
    squareButton(stopwatch),
    if (landscape)
      const VerticalDivider(width: 1, thickness: 1)
    else
      const Divider(height: 1, thickness: 1),
    squareButton(shopwatch),
  ];
}

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = primary ? colors.primary : colors.surfaceContainer;
    final foregroundColor = primary ? colors.onPrimary : colors.onSurface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: foregroundColor),
                const SizedBox(height: 20),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
