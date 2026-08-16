/// Emulator test bootstrap (ADR-0002). Requires the Firestore emulator on
/// localhost:8080 (CI service container).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:integration_test/integration_test.dart';

Future<void> initializeFirebase() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: 'fake-app-id',
        messagingSenderId: 'fake-sender-id',
        projectId: 'demo-project',
      ),
    );
  }
  final firestore = FirebaseFirestore.instance;
  try {
    firestore.useFirestoreEmulator('localhost', 8080);
  } catch (_) {
    // Already configured.
  }
}

Future<void> clearFirestoreEmulator() async {
  final firestore = FirebaseFirestore.instance;
  final collections = [
    'users',
    'posts',
    'comments',
    'tasks',
    'enumUsers',
    'enumTasks',
    'simpleEnumTasks',
    'fieldPathContract',
  ];
  for (final name in collections) {
    final snap = await firestore.collection(name).get();
    final batch = firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
