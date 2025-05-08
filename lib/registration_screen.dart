import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController securityAnswerController = TextEditingController();
  String selectedQuestion = 'What is your pet name?';

  // Function to register the user
  void _register() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    String securityAnswer = securityAnswerController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || securityAnswer.isEmpty) {
      _showMessage("Please fill all fields!");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match!");
      return;
    }

    final existingUser = await DatabaseHelper.instance.getUser(email);
    if (existingUser != null) {
      _showMessage("Email already exists!");
      return;
    }

    try {
      int userID = await DatabaseHelper.instance.insertUser({
        'username': username,
        'email': email,
        'password': password,
        'security_question': selectedQuestion,
        'security_answer': securityAnswer,
      });

      if (userID > 0) {
        _showMessage("Registration successful!", isSuccess: true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      } else {
        _showMessage("Registration failed. Try again.");
      }
    } catch (e) {
      print('Registration error: $e');
      _showMessage("Something went wrong. Please try again.");
    }
  }

  // Function to display a message
  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Username')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: confirmPasswordController, decoration: InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            DropdownButtonFormField<String>(
              value: selectedQuestion,
              decoration: InputDecoration(labelText: 'Select Security Question'),
              items: ['What is your pet name?', 'What is your mother\'s maiden name?', 'What was your first school?']
                  .map((String question) {
                return DropdownMenuItem<String>(value: question, child: Text(question));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedQuestion = newValue!;
                });
              },
            ),
            TextField(controller: securityAnswerController, decoration: InputDecoration(labelText: 'Security Answer')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text('Sign Up')),
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
