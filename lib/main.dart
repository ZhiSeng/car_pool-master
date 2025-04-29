import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'retrieve_password_screen.dart';

void main() => runApp(MyApp());

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
