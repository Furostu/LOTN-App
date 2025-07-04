import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'Services/auth_service.dart';
import 'Services/song_repository.dart';
import 'Pages/song_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings =
  const Settings(persistenceEnabled: true);

  final authService = AuthService();

  print("▶️ Starting MyApp with providers");

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    print("🏠 Building MyApp");

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => SongRepository()),
      ],
      child: MaterialApp(
        title: 'Chord Sheet App',
        debugShowCheckedModeBanner: false,
        home: const SongListPage(),
      ),
    );
  }
}
