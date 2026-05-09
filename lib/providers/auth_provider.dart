import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

class AuthState {
  final bool isSignedIn;
  final bool isPro;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isLoading;

  const AuthState({
    this.isSignedIn = false,
    this.isPro = false,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isSignedIn,
    bool? isPro,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? isLoading,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isPro: isPro ?? this.isPro,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _refreshAuthState();
    return const AuthState();
  }

  Future<void> _refreshAuthState() async {
    final fb = FirebaseService.instance;
    if (fb.isSignedIn) {
      final isPro = await fb.getProStatus();
      state = AuthState(
        isSignedIn: true,
        isPro: isPro,
        displayName: fb.displayName,
        email: fb.email,
        photoUrl: fb.photoUrl,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    final user = await FirebaseService.instance.signInWithGoogle();
    if (user != null) {
      final isPro = await FirebaseService.instance.getProStatus();
      state = AuthState(
        isSignedIn: true,
        isPro: isPro,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true);
    final user = await FirebaseService.instance.signInAnonymously();
    if (user != null) {
      state = AuthState(
        isSignedIn: true,
        displayName: 'Guest',
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    await FirebaseService.instance.signOut();
    state = const AuthState();
  }

  void setProStatus(bool isPro) {
    state = state.copyWith(isPro: isPro);
    FirebaseService.instance.setProStatus(isPro);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
