import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';

class RetrievePasswordScreen extends StatefulWidget {
  @override
  _RetrievePasswordScreenState createState() => _RetrievePasswordScreenState();
}

class _RetrievePasswordScreenState extends State<RetrievePasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController securityAnswerController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  String? securityQuestion;
  bool emailChecked = false;

  Future<void> _checkEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your email first.");
      return;
    }

    final user = await DatabaseHelper.instance.getUser(email);
    if (user != null) {
      setState(() {
        securityQuestion = user['security_question'];
        emailChecked = true;
      });
    } else {
      _showMessage("Email not found.");
    }
  }

  void _resetPassword() async {
    String email = emailController.text.trim();
    String answer = securityAnswerController.text.trim();
    String newPassword = newPasswordController.text.trim();

    if (email.isEmpty || answer.isEmpty || newPassword.isEmpty) {
      _showMessage("Please fill in all fields.");
      return;
    }

    final user = await DatabaseHelper.instance.getUser(email);
    if (user != null &&
        user['security_answer'].toString().toLowerCase() == answer.toLowerCase()) {
      await DatabaseHelper.instance.updateUserPassword(email, newPassword);
      _showMessage("Password updated successfully!", isSuccess: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      _showMessage("Incorrect answer or email not found.");
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Retrieve Password")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              onSubmitted: (_) => _checkEmail(),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkEmail,
              child: Text("Get Security Question"),
            ),
            if (securityQuestion != null) ...[
              SizedBox(height: 20),
              Text(
                "Security Question:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(securityQuestion!),
              TextField(
                controller: securityAnswerController,
                decoration: InputDecoration(labelText: 'Your Answer'),
              ),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetPassword,
                child: Text('Reset Password'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
