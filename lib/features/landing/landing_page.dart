import 'package:flutter/material.dart';

import '../../app/router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose your timer',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.classicStopwatch),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Stopwatch'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.shopwatch),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Shopwatch'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
