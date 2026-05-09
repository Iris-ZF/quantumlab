import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

const _usePopupOnWeb = kIsWeb;

/// Central Firebase service for auth, Firestore, and data sync.
/// Designed to gracefully degrade when Firebase is not configured.
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth?.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get userId => currentUser?.uid;
  String? get displayName => currentUser?.displayName;
  String? get email => currentUser?.email;
  String? get photoUrl => currentUser?.photoURL;

  /// Initialize Firebase. Call once at app startup.
  /// Returns false if Firebase is not configured (app works offline).
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Enable offline persistence
      _firestore!.settings = const Settings(persistenceEnabled: true);

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Firebase init failed (offline mode): $e');
      return false;
    }
  }

  // ── Authentication ──

  Future<User?> signInWithGoogle() async {
    if (!_initialized || _auth == null) return null;
    try {
      User? user;
      if (_usePopupOnWeb) {
        final provider = GoogleAuthProvider();
        final result = await _auth!.signInWithPopup(provider);
        user = result.user;
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;
        if (accessToken == null && idToken == null) {
          debugPrint('Google auth tokens are null');
          return null;
        }
        final credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );
        final result = await _auth!.signInWithCredential(credential);
        user = result.user;
      }
      if (user == null) return null;
      await _ensureUserDoc(user);
      return user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  Future<User?> signInAnonymously() async {
    if (!_initialized || _auth == null) return null;
    try {
      final result = await _auth!.signInAnonymously();
      final user = result.user;
      if (user == null) return null;
      await _ensureUserDoc(user);
      return user;
    } catch (e) {
      debugPrint('Anonymous sign-in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!_usePopupOnWeb) {
      await _googleSignIn.signOut();
    }
    await _auth?.signOut();
  }

  Future<void> _ensureUserDoc(User user) async {
    if (_firestore == null) return;
    final doc = _firestore!.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'isPro': false,
        'lessonProgress': {},
        'qasmLessonProgress': {},
      });
    }
  }

  // ── Lesson Progress ──

  Future<Map<String, dynamic>> getLessonProgress() async {
    if (!isSignedIn || _firestore == null) return {};
    try {
      final doc = await _firestore!.collection('users').doc(userId).get();
      return (doc.data()?['lessonProgress'] as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveLessonProgress(String lessonId, Map<String, dynamic> progress) async {
    if (!isSignedIn || _firestore == null) return;
    try {
      await _firestore!.collection('users').doc(userId).set({
        'lessonProgress': {lessonId: progress},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save lesson progress error: $e');
    }
  }

  Future<Map<String, dynamic>> getQasmLessonProgress() async {
    if (!isSignedIn || _firestore == null) return {};
    try {
      final doc = await _firestore!.collection('users').doc(userId).get();
      return (doc.data()?['qasmLessonProgress'] as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveQasmLessonProgress(String lessonId, Map<String, dynamic> progress) async {
    if (!isSignedIn || _firestore == null) return;
    try {
      await _firestore!.collection('users').doc(userId).set({
        'qasmLessonProgress': {lessonId: progress},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save QASM lesson progress error: $e');
    }
  }

  // ── Pro Purchase ──

  Future<bool> getProStatus() async {
    if (!isSignedIn || _firestore == null) return false;
    try {
      final doc = await _firestore!.collection('users').doc(userId).get();
      return doc.data()?['isPro'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setProStatus(bool isPro) async {
    if (!isSignedIn || _firestore == null) return;
    try {
      await _firestore!.collection('users').doc(userId).set({
        'isPro': isPro,
        'proActivatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Set pro status error: $e');
    }
  }

  // ── Circuit History ──

  Future<void> saveCircuitToHistory(Map<String, dynamic> circuitData) async {
    if (!isSignedIn || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('circuitHistory')
          .add({
        ...circuitData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Save circuit error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCircuitHistory({int limit = 50}) async {
    if (!isSignedIn || _firestore == null) return [];
    try {
      final query = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('circuitHistory')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return query.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Experience / Stats ──

  Future<void> recordExperience(String action, {Map<String, dynamic>? data}) async {
    if (!isSignedIn || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('experience')
          .add({
        'action': action,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
