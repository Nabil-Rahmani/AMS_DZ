import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:auction_app2/core/services/auth/auth_service.dart';
import 'package:auction_app2/shared/models/user_model.dart';
import 'package:auction_app2/core/routes/app_routes.dart';
import 'package:auction_app2/features/auth/screens/login_screen.dart';

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

        return FutureBuilder<UserModel?>(
          future: AuthService().getUserModel(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = userSnapshot.data;
            if (user == null) return const LoginScreen();

            // Redirect based on role
            switch (user.role) {
              case UserRole.admin:
                return const AdminRedirect();
              case UserRole.organizer:
                return const OrganizerRedirect();
              case UserRole.bidder:
                return const BidderRedirect();
            }
          },
        );
      },
    );
  }
}

// Redirect helpers — these push the correct route
class AdminRedirect extends StatelessWidget {
  const AdminRedirect({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class OrganizerRedirect extends StatelessWidget {
  const OrganizerRedirect({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.organizerDashboard);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class BidderRedirect extends StatelessWidget {
  const BidderRedirect({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.browseAuctions);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
