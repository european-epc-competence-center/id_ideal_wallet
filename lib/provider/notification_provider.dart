import 'dart:convert';

import 'package:dart_ssi/util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider {
  final _localNotify = FlutterLocalNotificationsPlugin();

  // TODO android: correct image
  final AndroidInitializationSettings _initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // TODO ios: initialize local_notify https://pub.dev/packages/flutter_local_notifications#-ios-setup
  final _firebase = FirebaseMessaging.instance;

  String? firebaseToken;

  NotificationProvider(this.firebaseToken) {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    logger.d('existing token: $firebaseToken');
  }

  start() async {
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: _initializationSettingsAndroid,
    );
    await _localNotify.initialize(initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse);

    var notificationSettings = await _firebase.getNotificationSettings();
    var notStatus = notificationSettings.authorizationStatus;
    logger.d('firebase status: $notStatus');

    notificationSettings = await _firebase.requestPermission(provisional: true);

    _firebase.onTokenRefresh.listen((fcmToken) {
      logger.d('new fcm token: $fcmToken');
      firebaseToken = fcmToken;
      Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
          .storeConfig('firebaseToken', firebaseToken!);
      tokenToServer();
    }).onError((err) {
      // Error getting token.
      logger.d('fcm token error: $err');
    });

    RemoteMessage? initialMessage = await _firebase.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    } else {
      var storage = await SharedPreferences.getInstance();
      await storage.reload();
      var storedMessages = storage.getString('messages');
      if (storedMessages != null) {
        Map messagesJson = jsonDecode(storedMessages);

        Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
            .onNewMessages(messagesJson.values
                .map((e) => SimplifiedNotification.fromJson(e))
                .toList());

        storage.remove('messages');
      }
    }
  }

  Future<String?> getInitialToken() async {
    firebaseToken = await _firebase.getToken();
    logger.d('initialToken: $firebaseToken');
    return firebaseToken;
  }

  void tokenToServer() async {
    var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
        listen: false);
    var authJwt = wallet.generateAuthJwt('abcde');
    var res = await post(Uri.parse(messagingBackend),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authJwt'
        },
        body: jsonEncode({
          'firebaseId': firebaseToken,
          'accounts': wallet.accountVcs.values.map((e) => e.id).toList()
        }));

    logger.d('register: ${res.statusCode}');
  }

  void _handleMessage(RemoteMessage message) async {
    logger.d(message.notification);
    var storage = await SharedPreferences.getInstance();
    var storedMessages = storage.getString('messages');

    Map messagesJson = storedMessages == null ? {} : jsonDecode(storedMessages);
    logger.d(storedMessages);
    messagesJson.remove(message.messageId);

    Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
        .onNewMessages(messagesJson.values
            .map((e) => SimplifiedNotification.fromJson(e))
            .toList());
    Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
        .onMessageOpen(SimplifiedNotification.fromRemoteMessage(message));

    storage.remove('messages');
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            ticker: 'ticker');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    var simple = SimplifiedNotification.fromRemoteMessage(message);
    await _localNotify.show(0, simple.notificationTitle,
        simple.notificationBody, notificationDetails,
        payload: simple.toString());

    Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
        .onNewMessage(simple);
  }

  void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    logger.d('notification payload: ${notificationResponse.payload}');
    Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
        .onMessageOpen(
            SimplifiedNotification.fromJson(notificationResponse.payload));
  }
}

class SimplifiedNotification {
  String notificationBody, notificationTitle;
  String targetAccount;
  Map<String, dynamic>? additionalData;

  SimplifiedNotification(
      this.notificationTitle, this.notificationBody, this.targetAccount,
      [this.additionalData]);

  factory SimplifiedNotification.fromRemoteMessage(RemoteMessage message) {
    return SimplifiedNotification(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        message.data['account'],
        message.data);
  }

  factory SimplifiedNotification.fromJson(dynamic jsonData) {
    var data = credentialToMap(jsonData);
    return SimplifiedNotification(
        data['notificationTitle'] ?? '',
        data['notificationBody'] ?? '',
        data['account'] ?? data['data']['account'] ?? '',
        (data['data'] as Map).map((k, v) => MapEntry(k as String, v)));
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationTitle': notificationTitle,
      'notificationBody': notificationBody,
      'account': targetAccount,
      'data': additionalData
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
