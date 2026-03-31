import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_auctions_screen.dart';
import '../screens/admin/verify_kyc_screen.dart';
import '../screens/organizer/organizer_dashboard.dart';
import '../screens/organizer/submit_auction_screen.dart';
import '../screens/organizer/track_auction_screen.dart';
import '../screens/organizer/kyc_upload_screen.dart';
import '../screens/bidder/browse_auctions_screen.dart';
import '../screens/bidder/bid_screen.dart';
import '../data/models/auction_model.dart';

class AppRoutes {
  // ── Route names ──────────────────────────────────────────────────
  static const String login              = '/login';
  static const String register           = '/register';

  static const String adminDashboard     = '/admin/dashboard';
  static const String manageUsers        = '/admin/users';
  static const String manageAuctions     = '/admin/auctions';
  static const String verifyKyc          = '/admin/kyc';

  static const String organizerDashboard = '/organizer/dashboard';
  static const String submitAuction      = '/organizer/submit-auction';
  static const String trackAuction       = '/organizer/track-auction';
  static const String kycUpload          = '/organizer/kyc-upload';

  static const String bidderDashboard    = '/bidder/dashboard';
  static const String browseAuctions     = '/bidder/browse';
  static const String bidScreen          = '/bidder/bid';

  // ── Route generator ──────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

    // Auth
      case login:
        return _route(const LoginScreen());
      case register:
        return _route(const RegisterScreen());

    // Admin
      case adminDashboard:
        return _route(const AdminDashboard());
      case manageUsers:
        return _route(const ManageUsersScreen());
      case manageAuctions:
        return _route(const ManageAuctionsScreen());
      case verifyKyc:
        return _route(const VerifyKycScreen());

    // Organizer
      case organizerDashboard:
        return _route(const OrganizerDashboard());
      case submitAuction:
        return _route(const SubmitAuctionScreen());
      case trackAuction:
        final auction = settings.arguments as AuctionModel;
        return _route(TrackAuctionScreen(auction: auction));
      case kycUpload:
        return _route(const KycUploadScreen());

    // Bidder
      case bidderDashboard:
        return _route(const BrowseAuctionsScreen());
      case browseAuctions:
        return _route(const BrowseAuctionsScreen());
      case MyBidsScreen:
        return _route(const MyBidsScreen());

      default:
        return _route(const LoginScreen());
    }
  }

  static Route<dynamic> _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
