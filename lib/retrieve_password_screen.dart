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
  final TextEditingController confirmPasswordController = TextEditingController();

  String? securityQuestion;
  bool emailChecked = false;
  bool _isNewPasswordVisible = false; // For new password visibility
  bool _isConfirmPasswordVisible = false; // For confirm password visibility

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
    String confirmPassword = confirmPasswordController.text.trim();

    // Validation checks for new password and confirm password
    if (email.isEmpty || answer.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Please fill in all fields.");
      return;
    }

    if (newPassword.length < 6) {
      _showMessage("Password must be at least 6 characters long!");
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage("New password and confirm password must match!");
      return;
    }

    final user = await DatabaseHelper.instance.getUser(email);
    if (user != null && user['security_answer'].toString().toLowerCase() == answer.toLowerCase()) {
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
      appBar: AppBar(
        title: Text("Forgot Password"),
        backgroundColor: Color(0xFF1976D2), // Consistent with the app theme
      ),
      body: SingleChildScrollView( // Makes the screen scrollable
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Input
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.blue),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Get Security Question Button
            ElevatedButton(
              onPressed: _checkEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button color
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Get Security Question", style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),

            // Display Security Question and Answer fields if email is valid
            if (securityQuestion != null) ...[
              Text(
                "Security Question:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(securityQuestion!, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),

              // Security Answer Input
              TextField(
                controller: securityAnswerController,
                decoration: InputDecoration(labelText: 'Your Answer'),
              ),
              SizedBox(height: 20),

              // New Password Input with Eye Icon
              TextField(
                controller: newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.blue),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Confirm Password Input with Eye Icon
              TextField(
                controller: confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: Colors.blue),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Reset Password Button
              ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Reset Password', style: TextStyle(fontSize: 18)),
              ),
            ],

            // Back to Login Button
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
