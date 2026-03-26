import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================
  // 🔹 Stream لمراقبة حالة تسجيل الدخول
  // ==========================
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==========================
  // 🔹 تسجيل مستخدم جديد
  // ==========================
  Future<String?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      // إنشاء المستخدم في Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // تخزين بيانات المستخدم في Firestore تحت collection 'khadamati'
      await _firestore
          .collection('khadamati')
          .doc(userCredential.user!.uid)
          .set({
        'fullName': fullName,
        'email': email,
        'role': role,
        'rating': 0,
        'totalReviews': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // نجاح العملية
    } on FirebaseAuthException catch (e) {
      return e.message; // رسالة الخطأ من Firebase
    } catch (e) {
      return e.toString(); // أي خطأ آخر
    }
  }

  // ==========================
  // 🔹 تسجيل الدخول
  // ==========================
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // تسجيل الدخول ناجح
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ==========================
  // 🔹 تسجيل الخروج
  // ==========================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ==========================
  // 🔹 جلب بيانات المستخدم الحالي
  // ==========================
  Future<DocumentSnapshot?> getUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      return await _firestore.collection('khadamati').doc(user.uid).get();
    } catch (e) {
      return null;
    }
  }
}
