import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auction_app2/core/services/firebase_messaging_service.dart';
import 'package:auction_app2/core/routes/app_routes.dart';
import 'package:auction_app2/features/auth/screens/login_screen.dart';
import 'package:auction_app2/features/bidder/screens/interests_onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final firebaseUser = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            final data       = userSnapshot.data!.data() as Map<String, dynamic>;
            final isVerified = data['isVerified'] as bool? ?? false;

            // ✅ غير متحقق — ابقى في مكانك (شاشة التحقق شغالة)
            if (!isVerified) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = data['role'] as String? ?? 'bidder';

            switch (role) {
              case 'admin':
                return const AdminRedirect();
              case 'organizer':
                return const OrganizerRedirect();
              default:
                return BidderInterestsCheck(uid: firebaseUser.uid);
            }
          },
        );
      },
    );
  }
}

// ✅ يتحقق إذا المزايد حدد اهتماماته أو لا
class BidderInterestsCheck extends StatefulWidget {
  final String uid;
  const BidderInterestsCheck({super.key, required this.uid});

  @override
  State<BidderInterestsCheck> createState() => _BidderInterestsCheckState();
}

class _BidderInterestsCheckState extends State<BidderInterestsCheck> {
  @override
  void initState() {
    super.initState();
    FirebaseMessagingService.onLogin();
    _check();
  }

  Future<void> _check() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    final data         = doc.data();
    final hasInterests = data?['interests'] != null &&
        (data!['interests'] as List).isNotEmpty;

    if (!mounted) return;

    if (hasInterests) {
      Navigator.pushReplacementNamed(context, AppRoutes.browseAuctions);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InterestsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ── Admin Redirect ──
class AdminRedirect extends StatefulWidget {
  const AdminRedirect({super.key});
  @override
  State<AdminRedirect> createState() => _AdminRedirectState();
}

class _AdminRedirectState extends State<AdminRedirect> {
  @override
  void initState() {
    super.initState();
    FirebaseMessagingService.onLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ── Organizer Redirect ──
class OrganizerRedirect extends StatefulWidget {
  const OrganizerRedirect({super.key});
  @override
  State<OrganizerRedirect> createState() => _OrganizerRedirectState();
}

class _OrganizerRedirectState extends State<OrganizerRedirect> {
  @override
  void initState() {
    super.initState();
    FirebaseMessagingService.onLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.organizerDashboard);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ── Bidder Redirect ──
class BidderRedirect extends StatefulWidget {
  const BidderRedirect({super.key});
  @override
  State<BidderRedirect> createState() => _BidderRedirectState();
}

class _BidderRedirectState extends State<BidderRedirect> {
  @override
  void initState() {
    super.initState();
    FirebaseMessagingService.onLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.browseAuctions);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}