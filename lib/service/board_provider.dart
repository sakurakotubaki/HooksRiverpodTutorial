import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Firebaseを使うためのProvider
final firebaseProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
