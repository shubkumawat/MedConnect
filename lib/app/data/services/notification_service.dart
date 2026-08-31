import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';
import '../../core/Util/Print/print_log.dart';
import 'storage_service.dart';

/// Handles a push that arrives while the app is backgrounded/terminated.
///
/// This runs in its own background isolate (separate from the app's main
/// isolate), so it can't see any state built up in [NotificationService] —
/// it has to re-init Firebase itself. Must stay a top-level/static function
/// (required by `firebase_messaging`) and keep the `vm:entry-point` pragma
/// so the Android/iOS embedding can find it after tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  PrintLog.printLog(
      'FCM (background): ${message.messageId} - ${message.notification?.title}');
}

/// Wires up Firebase Cloud Messaging: permission prompt, token retrieval,
/// and showing/handling notifications in every app state (foreground,
/// background, terminated).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android 8+ requires every notification to belong to a channel; this is
  /// the one FCM falls back to when a push doesn't name one explicitly (see
  /// the matching `default_notification_channel_id` meta-data in the
  /// AndroidManifest).
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'General Notifications',
    description: 'Medication reminders, appointment alerts and app updates.',
    importance: Importance.high,
  );

  String? fcmToken;

  /// Fired when the user taps a notification (foreground display, a
  /// background tap, or a cold-start launch from one). The app doesn't use
  /// named GetX routes today, so wire this up wherever the navigator/root
  /// widget is available instead of routing inside this service, e.g.:
  /// `NotificationService.instance.onNotificationTap = (data) => Get.to(() => TargetScreen());`
  void Function(Map<String, dynamic> data)? onNotificationTap;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _initLocalNotifications();

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // iOS shows nothing while the app is foregrounded unless told to.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _fetchAndStoreToken();
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // App was launched by tapping a push while fully terminated. This runs
    // before runApp(), so GetMaterialApp has no navigator yet — wait a beat
    // for the first frame before routing.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 800),
          () => _onNotificationTap(initialMessage));
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    PrintLog.printLog('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // Permission is already requested above via FirebaseMessaging.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // payload carries the JSON-encoded `message.data` set in
        // _onForegroundMessage below.
        if (response.payload != null && response.payload!.isNotEmpty) {
          onNotificationTap?.call(jsonDecode(response.payload!));
        }
      },
    );
  }

  Future<void> _fetchAndStoreToken() async {
    try {
      if (Platform.isIOS) {
        // FCM can't hand out a token until APNs has assigned its own — poll
        // briefly since that assignment can lag just after app launch.
        String? apnsToken = await _messaging.getAPNSToken();
        var attempts = 0;
        while (apnsToken == null && attempts < 5) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _messaging.getAPNSToken();
          attempts++;
        }
      }
      fcmToken = await _messaging.getToken();
      PrintLog.printLog('FCM token: $fcmToken');
      if (fcmToken != null) {
        await StorageService().setString(StorageService.fcmToken, fcmToken!);
        // TODO: POST fcmToken to the backend once a "register device" API
        // endpoint exists, so the server can target this device.
      }
    } catch (e) {
      PrintLog.printLog('FCM token fetch failed: $e');
    }
  }

  /// Best-effort current FCM token for use in API calls (e.g. login/verify
  /// OTP) — the in-memory value set by [init], falling back to the last
  /// value persisted to storage in case this is called before [init]
  /// finishes fetching a fresh one.
  Future<String> currentToken() async {
    if (fcmToken != null && fcmToken!.isNotEmpty) return fcmToken!;
    return StorageService().getString(StorageService.fcmToken);
  }

  void _onTokenRefresh(String token) {
    fcmToken = token;
    StorageService().setString(StorageService.fcmToken, token);
    // TODO: re-sync the refreshed token with the backend (see above).
  }

  /// Push arrived while the app was open — FCM won't surface a system
  /// notification on its own here, so show one via flutter_local_notifications.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    PrintLog.printLog('FCM (foreground): ${message.messageId}');
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// User tapped a notification (from background or terminated state).
  void _onNotificationTap(RemoteMessage message) {
    PrintLog.printLog('Notification tapped: ${message.data}');
    onNotificationTap?.call(message.data);
  }

  /// Show a local system notification (e.g. emergency SOS from Home).
  Future<void> showLocal({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
