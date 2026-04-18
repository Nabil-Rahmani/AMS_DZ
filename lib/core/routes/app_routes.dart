import 'package:flutter/material.dart';
import 'package:auction_app2/features/auth/screens/login_screen.dart';
import 'package:auction_app2/features/auth/screens/register_screen.dart';
import 'package:auction_app2/features/admin/screens/admin_dashboard.dart';
import 'package:auction_app2/features/admin/screens/manage_users_screen.dart';
import 'package:auction_app2/features/admin/screens/manage_auctions_screen.dart';
import 'package:auction_app2/features/admin/screens/verify_kyc_screen.dart';
import 'package:auction_app2/features/organizer/screens/organizer_dashboard.dart';
import 'package:auction_app2/features/organizer/screens/submit_auction_screen.dart';
import 'package:auction_app2/features/organizer/screens/track_auction_screen.dart';
import 'package:auction_app2/features/organizer/screens/kyc_upload_screen.dart';
import 'package:auction_app2/features/bidder/screens/browse_auctions_screen.dart';
import 'package:auction_app2/features/bidder/screens/my_bids_screen.dart';
import 'package:auction_app2/shared/models/auction_model.dart';
import 'package:auction_app2/shared/wallet_screen.dart';
class AppRoutes {
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
  static const String myBids             = '/bidder/my-bids'; // FIX: was using class name as case
  static const String wallet             = '/bidder/wallet';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:              return _route(const LoginScreen());
      case register:           return _route(const RegisterScreen());
      case adminDashboard:     return _route(const AdminDashboard());
      case manageUsers:        return _route(const ManageUsersScreen());
      case manageAuctions:     return _route(const ManageAuctionsScreen());
      case verifyKyc:          return _route(const VerifyKycScreen());
      case organizerDashboard: return _route(const OrganizerDashboard());
      case submitAuction:      return _route(const SubmitAuctionScreen());
      case trackAuction:
        final auction = settings.arguments as AuctionModel;
        return _route(TrackAuctionScreen(auction: auction));
      case kycUpload:          return _route(const KycUploadScreen());
      case bidderDashboard:    return _route(const BrowseAuctionsScreen());
      case browseAuctions:     return _route(const BrowseAuctionsScreen());
      case myBids:             return _route(const MyBidsScreen());
      case AppRoutes.wallet:
        return MaterialPageRoute(
          builder: (_) => WalletScreen(),
        );
      default:                 return _route(const LoginScreen());
    }
  }

  static Route<dynamic> _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
