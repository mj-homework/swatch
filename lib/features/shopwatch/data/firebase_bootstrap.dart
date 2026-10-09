import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_leaderboard_repository.dart';
import 'leaderboard_repository.dart';

/// Explicit opt-in only. No config means no platform calls or startup delay.
Future<LeaderboardRepository> initializeLeaderboard() async {
  const enabled = bool.fromEnvironment('SHOPWATCH_FIREBASE');
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  if (!enabled || [apiKey, appId, projectId, sender].any((s) => s.isEmpty)) {
    return const OfflineLeaderboardRepository();
  }
  try {
    final app = await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: apiKey, appId: appId, messagingSenderId: sender, projectId: projectId,
    )).timeout(const Duration(seconds: 5));
    return FirestoreLeaderboardRepository(auth: FirebaseAuth.instanceFor(app: app),
      firestore: FirebaseFirestore.instanceFor(app: app));
  } catch (_) { return const OfflineLeaderboardRepository(); }
}
