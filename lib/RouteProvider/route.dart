import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';



Route<dynamic>? generateRoute(RouteSettings settings){
  switch(settings.name){



    // case assesmentScreen:
    //   return MaterialPageRoute(builder: (context) => AssesmentScreen());
    //
    // case splashScreenRoute:
    // return MaterialPageRoute(builder: (context) => const SplashScreen());

 //  // case assesmentScreen:
 //  //     return PageTransition(type: PageTransitionType.rightToLeft,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const AssesmentScreen());
 //  //   //
 //    case b2b_introScreenRoute:
 //      return PageTransition(type: PageTransitionType.rightToLeft,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const B2BIntroScreen());
 //
 //      case loginScreenRoute:
 //      return PageTransition(type: PageTransitionType.rightToLeft,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const LoginScreen());

 //    case loginScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const LoginScreen());
 //
 //    case b2b_registerScreenRoute:
 //      var args = settings.arguments as B2BRegisterScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BRegisterScreen(mobileno: args.mobileno,));
 //



      // case AddToCartScreenRoute:
      // var args = settings.arguments as AddToCartScreen;
      // return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: AddToCartScreen(slug: args.slug));

      // case MyAddressScreenRoute:
      // var args = settings.arguments as MyAddressScreen;
      // return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: MyAddressScreen());
      //

     // case subCategoryScreenRoute:
     //  var args = settings.arguments as SubCategoryScreen;
     //  return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: SubCategoryScreen(categoryId: args.categoryId,));

      // case ProductListScreenRoute:
      // var args = settings.arguments as AccountScreen;
      // return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: AccountScreen());
      //

 //
 //    case b2b_otpScreenRoute:
 //      final args = settings.arguments as B2BOTPScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BOTPScreen(type: args.type,));
 //
 //      case otpScreenRoute:
 //      final args = settings.arguments as B2BOTPScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: OTPScreen(type: args.type,));
 //
 //    case b2b_dashboardScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const B2BDashboardScreen());
 //
 //
 //    case dashboardScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const DashboardScreen());
 //
 //
 //    case b2b_profileScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const B2BProfileScreen());
 //
 //      case profileScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const ProfileScreen());
 //
 //    case b2b_operatorScreenRoute:
 //      final args = settings.arguments as B2BRechargeScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BRechargeScreen(operatorId: args.operatorId, operatorImg: "", mobile: args.mobile,type: args.type,));
 //
 //      case operatorScreenRoute:
 //      final args = settings.arguments as B2BRechargeScreen;
 //      // return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: RechargeScreen(operatorId: args.operatorId, operatorImg: "", mobile: args.mobile,type: args.type,));
 //
 //    case b2b_billPaymentScreenRoute:
 //      final args = settings.arguments as B2BBillPaymentScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BBillPaymentScreen(type : args.type,operatorName: args.operatorName,operatorId: args.operatorId, operatorImg: args.operatorImg, operatorCode: args.operatorCode,txnCategory: args.txnCategory,));
 //
 //      case billPaymentScreenRoute:
 //      final args = settings.arguments as B2BBillPaymentScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: BillPaymentScreen(type : args.type,operatorName: args.operatorName,operatorId: args.operatorId, operatorImg: args.operatorImg, operatorCode: args.operatorCode,txnCategory: args.txnCategory,));
 //
 //    case b2b_receiptScreenRoute:
 //      final args = settings.arguments as B2BReceiptScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BReceiptScreen(receiptDetails: args.receiptDetails,amount: args.amount,mobileNo: args.mobileNo,));
 //
 //      case receiptScreenRoute:
 //      final args = settings.arguments as B2BReceiptScreen;
 //      // return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: ReceiptScreen(receiptDetails: args.receiptDetails,amount: args.amount,mobileNo: args.mobileNo,));
 //
 //    case b2b_pgReceiptScreenRoute:
 //      final args = settings.arguments as B2BPGReceiptScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BPGReceiptScreen(txnID: args.txnID,));
 //
 //      case pgReceiptScreenRoute:
 //      final args = settings.arguments as B2BPGReceiptScreen;
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: PGReceiptScreen(txnID: args.txnID,));
 //
 //    case b2b_changePasswordScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const B2BChangePasswordScreen());
 //
 //      case changePasswordScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const ChangePasswordScreen());
 //
 //      case b2b_commissionSScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BCommissionSScreen());
 //
 //      case commissionSScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: CommissionSScreen());
 //
 //
 //      case b2b_newReceiptScreenRoute:
 //        final args = settings.arguments as B2BNewReceiptScreen;
 //        return PageTransition(type: PageTransitionType.rightToLeft,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BNewReceiptScreen(amount: args.amount,receiptDetails: args.receiptDetails,messsage: args.messsage));
 //
 //        case newReceiptScreenRoute:
 //        final args = settings.arguments as B2BNewReceiptScreen;
 //        // return PageTransition(type: PageTransitionType.rightToLeft,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: NewReceiptScreen(amount: args.amount,receiptDetails: args.receiptDetails,messsage: args.messsage));
 //
 //
 //      case b2b_referralScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BReferralScreen());
 //
 //      case referralScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: ReferralScreen());
 //
 //      case b2b_raiseComplainScreenRoute:
 //        final args = settings.arguments as B2BRaiseComplainScreen;
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BRaiseComplainScreen(reportId: args.reportId,status: args.status,));
 //
 //      case raiseComplainScreenRoute:
 //        final args = settings.arguments as B2BRaiseComplainScreen;
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: RaiseComplainScreen(reportId: args.reportId,status: args.status,));
 //
 //      case  b2b_viewReceiptScreenRoute:
 //        final args = settings.arguments as B2BViewReceiptScreen;
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BViewReceiptScreen(isSuccess: args.isSuccess,receiptDetails: args.receiptDetails,));
 //
 //        case  viewReceiptScreenRoute:
 //        final args = settings.arguments as B2BViewReceiptScreen;
 //        // return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: ViewReceiptScreen(isSuccess: args.isSuccess,receiptDetails: args.receiptDetails,));
 //
 //      case  b2b_mobileValidation:
 //        final args = settings.arguments as B2BRechargeScreen;
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BRechargeScreen(operatorId: args.operatorId, operatorImg: "", mobile: args.mobile,type: args.type,));
 //
 // case  mobileValidation:
 //        final args = settings.arguments as RechargeScreen;
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: RechargeScreen(operatorId: args.operatorId, operatorImg: "", mobile: args.mobile,type: args.type,));
 //
 //      case  b2b_complainHistory:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BComplainHistoryScreen());
 //
 //        case  complainHistory:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: ComplainHistoryScreen());
 //
 //      case  b2b_gift_voucher_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BGiftVoucherScreen());
 //
 //        case  gift_voucher_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: GiftVoucherScreen());
 //
 //      case  b2b_gift_voucher_detilas_screen:
 //        final args = settings.arguments as B2BGiftVoucherDetailsScreen;
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BGiftVoucherDetailsScreen(voucherProviders: args.voucherProviders,));
 //
 //        case  gift_voucher_detilas_screen:
 //        final args = settings.arguments as B2BGiftVoucherDetailsScreen;
 //        // return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: GiftVoucherDetailsScreen(voucherProviders: args.voucherProviders,));
 //
 //      case  b2b_kyc_verify_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: B2BKYCScreen());
 //
 //        case  kyc_verify_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: KYCScreen());
 //
 //      case  b2b_paytm_description_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const B2BPaytmDescriptionScreen());
 //
 //        case  paytm_description_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const PaytmDescriptionScreen());
 //
 //      case  b2b_earn_paytm_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const B2BEarnPaytmScreen());
 //
 //        case  earn_paytm_screen:
 //        return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const EarnPaytmScreen());
 //
 //    case  b2b_subscriptionScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const SubscriptionNow());
 //
 //    case  b2b_BankDetailScreenRoute:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const BankDetailsScreen());
 //
 //    case  b2b_AddBankDetailsScreen:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const AddBankDetailsScreen());
 //
 //    case  b2b_FundTransferScreen:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const FundTransferScreen());
 //
 //    case  b2b_FundMoveScreen:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const FundMoveScreen());
 //
 //    case  b2b_WithdrawalListScreen:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const Withdrawallistscreen());
 //
 //    case  b2b_TotalSponsarScreen:
 //      return PageTransition(type: PageTransitionType.bottomToTop,duration: const Duration(milliseconds: 350),alignment: Alignment.center, child: const TotalSponsorScreen());
 //
    default:
      // return MaterialPageRoute(builder: (context) => const SplashScreen());

     }
}