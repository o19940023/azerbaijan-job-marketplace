import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppUser {
  final String id;
  final String email;
  final String userType; // 'employer' or 'job_seeker'

  AppUser({
    required this.id,
    required this.email,
    required this.userType,
  });
}

class FirebaseAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<AppUser> login({
    required String email,
    required String password,
    required String expectedUserType,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = _auth.currentUser;
    if (user == null) throw Exception('Təsdiqləmə xətası');

    // Fetch user type from Firestore
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('İstifadəçi tapılmadı. Zəhmət olmasa qeydiyyatdan keçin.');
    }

    final data = doc.data()!;
    final actualUserType = data['userType'] as String? ?? '';

    if (actualUserType != expectedUserType) {
      await _auth.signOut();
      throw Exception('Bu hesabla $expectedUserType olaraq daxil ola bilməzsiniz.');
    }

    _currentUser = AppUser(
      id: user.uid,
      email: user.email ?? email,
      userType: actualUserType,
    );

    // Save FCM token for push notifications
    await _saveFcmToken(user.uid);

    return _currentUser!;
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String userType,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = _auth.currentUser;
    if (user == null) throw Exception('Qeydiyyat xətası');

    // Create a new document in Firestore with the user's role
    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'userType': userType,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _currentUser = AppUser(
      id: user.uid,
      email: user.email ?? email,
      userType: userType,
    );

    // Save FCM token for push notifications
    await _saveFcmToken(user.uid);

    return _currentUser!;
  }

  Future<AppUser> signInWithGoogle(String expectedUserType) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? '591328908781-stqgmmde3lohjgaune8r2o7b6u1um820.apps.googleusercontent.com' : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google ilə giriş ləğv edildi.');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) throw Exception('Google ilə giriş xətası.');

      return await _handleSocialUserDoc(
        user: user,
        expectedUserType: expectedUserType,
        fullName: user.displayName ?? googleUser.displayName ?? 'Adsız İstifadəçi',
        photoUrl: user.photoURL ?? googleUser.photoUrl,
      );
    } catch (e) {
      throw Exception('Google Auth xətası: $e');
    }
  }

  Future<AppUser> signInWithApple(String expectedUserType) async {
    try {
      UserCredential userCredential;
      String fullName = 'Adsız İstifadəçi';

      if (Platform.isAndroid) {
        // Android üçün Firebase-in yerli Google Custom Tab interfeysini istifadə edirik (Xətasız işləyir)
        final provider = OAuthProvider('apple.com');
        provider.addScope('email');
        provider.addScope('name');
        
        userCredential = await _auth.signInWithProvider(provider);
        final user = userCredential.user;
        if (user == null) throw Exception('Apple ilə giriş xətası.');
        
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          fullName = user.displayName!;
        } else if (userCredential.additionalUserInfo?.profile != null) {
           final profile = userCredential.additionalUserInfo!.profile!;
           print('APPLE RAW PROFILE: $profile');
           if (profile.containsKey('name')) {
             fullName = profile['name'] as String;
           } else if (profile.containsKey('firstName') || profile.containsKey('lastName')) {
             fullName = '${profile["firstName"] ?? ""} ${profile["lastName"] ?? ""}'.trim();
           }
        }
      } else {
        // iOS üçün native Apple pəncərəsini istifadə edirik
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        final OAuthProvider appleProvider = OAuthProvider('apple.com');
        final OAuthCredential credential = appleProvider.credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
          rawNonce: rawNonce,
        );

        userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) throw Exception('Apple ilə giriş xətası.');

        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          fullName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          fullName = user.displayName!;
        }
      }

      final User? finalUser = userCredential.user;
      
      if (fullName == 'Adsız İstifadəçi' || fullName.trim().isEmpty) {
        if (finalUser?.displayName != null && finalUser!.displayName!.isNotEmpty) {
          fullName = finalUser.displayName!;
        } else if (finalUser?.email != null && finalUser!.email!.isNotEmpty) {
          final prefix = finalUser.email!.split('@').first;
          if (prefix.isNotEmpty) {
            fullName = prefix[0].toUpperCase() + prefix.substring(1).replaceAll(RegExp(r'[._-]'), ' ');
          }
        }
      }

      return await _handleSocialUserDoc(
        user: finalUser!,
        expectedUserType: expectedUserType,
        fullName: fullName.isEmpty ? 'Adsız İstifadəçi' : fullName,
        photoUrl: finalUser.photoURL,
      );
    } catch (e) {
      throw Exception('Apple Auth xətası: $e');
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset = '01234567839abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex form.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AppUser> _handleSocialUserDoc({
    required User user,
    required String expectedUserType,
    required String fullName,
    String? photoUrl,
  }) async {
    print('--- SOCIAL LOGIN DATA ---');
    print('Provider ID: \${user.providerData.map((e) => e.providerId).join(", ")}');
    print('Incoming fullName: \$fullName');
    print('Incoming photoUrl: \$photoUrl');
    print('User displayName: \${user.displayName}');
    print('User photoURL: \${user.photoURL}');
    print('-------------------------');

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      // New user
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'userType': expectedUserType,
        'createdAt': FieldValue.serverTimestamp(),
        'fullName': fullName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      _currentUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        userType: expectedUserType,
      );
    } else {
      // Existing user
      final data = doc.data()!;
      final actualUserType = data['userType'] as String? ?? '';

      if (actualUserType != expectedUserType) {
        await _auth.signOut();
        throw Exception('Bu hesabla $expectedUserType olaraq daxil ola bilməzsiniz.');
      }

      // Mövcud istifadəçinin adı və ya şəkli yoxdursa, Google/Apple-dan gələnlərlə yeniləyirik
      final Map<String, dynamic> updates = {};
      final currentName = data['fullName'] as String?;
      final currentPhoto = data['photoUrl'] as String?;

      final isCurrentNameEmpty = currentName == null || currentName.trim().isEmpty || currentName == 'Adsız İstifadəçi';
      final isValidNewName = fullName.trim().isNotEmpty && fullName != 'Adsız İstifadəçi';

      print('Current DB Name: \$currentName | isValidNewName: \$isValidNewName | isCurrentEmpty: \$isCurrentNameEmpty');

      // Əgər Firestore-da ARTIQ əsl ad varsa, onu saxla (email-dən gələn ad ilə dəyişmə!)
      if (isValidNewName && isCurrentNameEmpty) {
        updates['fullName'] = fullName;
        print('-> Updating DB Name to: \$fullName');
      } else if (!isCurrentNameEmpty) {
        // Mövcud əsl adı qoru
        print('-> Keeping existing DB Name: \$currentName');
      }

      final isValidNewPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;
      final isCurrentPhotoEmpty = currentPhoto == null || currentPhoto.trim().isEmpty;

      print('Current DB Photo: \$currentPhoto | isValidNewPhoto: \$isValidNewPhoto | isCurrentEmpty: \$isCurrentPhotoEmpty');

      if (isValidNewPhoto && isCurrentPhotoEmpty) {
        updates['photoUrl'] = photoUrl;
        print('-> Updating DB Photo to: \$photoUrl');
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
        print('-> Pushed updates to Firestore: \$updates');
      }

      _currentUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        userType: actualUserType,
      );
    }

    await _saveFcmToken(user.uid);
    return _currentUser!;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  /// Saves the device's FCM token to Firestore so the backend can send push notifications
  Future<void> _saveFcmToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      // Non-critical: don't block login/register if token save fails
      print('FCM Token saxlama xətası: $e');
    }
  }
}
