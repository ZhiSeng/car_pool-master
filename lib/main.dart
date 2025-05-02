import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'retrieve_password_screen.dart';
import 'package:firebase_core/firebase_core.dart';  // Make sure this import is correct
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase before app starts
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpool App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),  // Start with the login screen
      routes: {
        '/register': (context) => RegistrationScreen(),
        '/retrievePassword': (context) => RetrievePasswordScreen(),
      },
    );
  }
}
