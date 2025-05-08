import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in both fields');
      return;
    }

    // Here you would typically check against admin credentials
    // For now, we'll use a simple check
    if (email == 'admin@admin.com' && password == 'admin123') {
      _showMessage('Admin Login Successful!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboard(),
        ),
      );
    } else {
      _showMessage('Invalid Admin Credentials');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Admin Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Admin Password'),
              obscureText: true,
            ),
            ElevatedButton(onPressed: _login, child: Text('Admin Login')),
          ],
        ),
      ),
    );
  }
} 