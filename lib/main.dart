import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/group_provider.dart';
import 'screens/group_admin_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }
  runApp(const AnApp());
}

class AnApp extends StatelessWidget {
  const AnApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupProvider(),
      child: MaterialApp(
        title: 'AnApp',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const CalendarScreen(),
        routes: {
          GroupAdminScreen.routeName: (_) => const GroupAdminScreen(),
          CalendarScreen.routeName: (_) => const CalendarScreen(),
        },
      ),
    );
  }
}
