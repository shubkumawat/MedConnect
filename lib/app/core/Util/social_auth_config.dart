/// Native + Firebase social login.
///
/// Google Sign-In (error 10 until this is done):
/// 1. Firebase Console → Project healaura-b7634 → Project settings → Your apps
///    → Android com.healora.app → Add fingerprint:
///    SHA-1:  6B:63:BA:88:28:6D:CF:71:47:CC:36:C1:74:86:52:A6:C5:06:5B:50
///    SHA-256: F2:AC:92:C1:A6:30:05:F7:47:94:B1:30:58:2D:8C:44:88:D5:6C:30:62:1B:65:69:57:0F:F6:C2:BE:50:FE:B0
/// 2. Authentication → Sign-in method → Google → Enable
/// 3. Download a new google-services.json (it must contain oauth_client) into android/app/
/// 4. Paste the Web client ID below (ends with .apps.googleusercontent.com)
///
/// Facebook: create an app at developers.facebook.com, then put App ID + Client
/// Token here AND in android strings.xml + ios Info.plist. Keep AutoInit off
/// until those IDs are real (App ID 0 causes Graph API 190 on launch).
class SocialAuthConfig {
  static const googleWebClientId =
      '496964329712-7ignm9q48mrccf32rn4dcdl5770pjj2l.apps.googleusercontent.com';

  /// Numeric Facebook App ID. Leave empty until the Facebook app is created.
  static const facebookAppId = '';
  static const facebookClientToken = '';

  static bool get isFacebookConfigured =>
      facebookAppId.trim().isNotEmpty && facebookClientToken.trim().isNotEmpty;
}
