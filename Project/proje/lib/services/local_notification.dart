import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// LocalNotification için bir class oluşturdum. Bu class ı her yerden kullanmak için.

class LocalNotification {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  // classın constructor ı. LocalNotification clasından instance oluşturduğum zaman içerisinde ki ayarlar aktif olacak.
  LocalNotification() {
// Buradaki ayarlar Flutter LocalNotification plugininden bakarak sağlandı. https://pub.dev/packages/flutter_local_notifications
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        iOS: initializationSettingsIOS, android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  // Bildirim göndermek için class içerisine bir fonksiyon oluşturduk.
  sendNow(String title, String body, String payload) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'NearNotify', 'Near Covid19', 'Temaslı/Hasta uyarısı',
        importance: Importance.max, priority: Priority.high, ticker: 'ticker');

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: payload);
  }
}
