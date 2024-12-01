import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // FirebaseAuth 추가
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart'; // FirebaseStorage 추가

class FirebaseInit {
  static final FirebaseInit _instance = FirebaseInit._internal();
  late FirebaseFirestore firestore;
  late FirebaseAuth auth;  // FirebaseAuth 인스턴스 추가
  late FirebaseStorage storage; // FirebaseStorage 인스턴스 추가

  factory FirebaseInit() {
    return _instance;
  }

  FirebaseInit._internal();

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    firestore = FirebaseFirestore.instance;
    auth = FirebaseAuth.instance;  // FirebaseAuth 인스턴스 초기화
    storage = FirebaseStorage.instance; // FirebaseStorage 인스턴스 초기화
  }
}
