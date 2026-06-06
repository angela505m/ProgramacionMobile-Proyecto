import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'firebase_options.dart';
import 'view/home_view.dart';
import 'view/login_view.dart';
import 'viewmodel/mascotaviewmodel.dart';
import 'viewmodel/usuarioviewmodel.dart';
import 'viewmodel/recordatorioviewmodel.dart';
import 'services/notification_service.dart';

// Manejador cuando la app está en segundo plano o totalmente cerrada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final NotificationService notif = NotificationService();
  await notif.init();
  await notif.showNow(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: message.notification?.title ?? 'Recordatorio',
    body: message.notification?.body ?? 'Revisa tu mascota',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar AndroidAlarmManager (necesario para alarmas nativas)
  await AndroidAlarmManager.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MascotaViewModel()),
        ChangeNotifierProvider(create: (_) => UsuarioViewModel()),
        ChangeNotifierProvider(create: (_) => RecordatorioViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PetCare',
        theme: ThemeData.light(),
        home: const LoginView(),
        routes: {'/home': (context) => const HomeView()},
      ),
    );
  }
}
