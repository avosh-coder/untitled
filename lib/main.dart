import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'src/features/screens/welcome_screen.dart';
import 'package:get/get.dart';

 Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
    await Firebase.initializeApp(options: FirebaseOptions(apiKey: "AIzaSyCsS7ps8VXilzIo2SXPzPHFtwDcUOUvmns", appId: "1:341339749526:web:0a7dc5bafd9a9f9ecc96b7", messagingSenderId: "341339749526", projectId: "flutter-firebase-28230"));
  }
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: WelcomeScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // int _counter = 0;

  /*void _incrementCounter() {
    setState(() {

      _counter++;
    });
  }*/

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
