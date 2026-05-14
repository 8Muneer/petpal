import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  
  print('--- SITTING REQUESTS ---');
  final requests = await db.collection('sitting_requests').get();
  for (var doc in requests.docs) {
    print('Request ID: ${doc.id}');
    print('  sitterUid: ${doc.data()['sitterUid']}');
    print('  ownerUid: ${doc.data()['ownerUid']}');
    print('  status: ${doc.data()['status']}');
  }

  print('\n--- SITTING SERVICES ---');
  final services = await db.collection('sitting_services').get();
  for (var doc in services.docs) {
    print('Service ID: ${doc.id}');
    print('  providerUid: ${doc.data()['providerUid']}');
    print('  providerName: ${doc.data()['providerName']}');
  }
}
