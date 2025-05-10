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
  bool _isPasswordVisible = false; // Boolean for password visibility
  bool _isConfirmPasswordVisible = false; // Boolean for confirm password visibility

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

    // Email validation check
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com|student\.tarc\.edu\.my)$").hasMatch(email)) {
      _showMessage("Please enter a valid email.");
      return;
    }

    // Password validation check (at least 6 characters)
    if (password.length < 6) {
      _showMessage("Password must be at least 6 characters!");
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
      appBar: AppBar(
        title: Text("Register"),
        backgroundColor: Color(0xFF1976D2), // Consistent with the app theme
      ),
      body: SingleChildScrollView( // Makes the screen scrollable
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Username Input
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.blue), // Consistent color
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Email Input
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.blue), // Consistent color
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Password Input with Eye Icon
            TextField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.blue), // Consistent color
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
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
                labelStyle: TextStyle(color: Colors.blue), // Consistent color
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

            // Dropdown for Security Question
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
            SizedBox(height: 20),

            // Security Answer Input
            TextField(
              controller: securityAnswerController,
              decoration: InputDecoration(labelText: 'Security Answer'),
            ),
            SizedBox(height: 20),

            // Sign Up Button
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Consistent button color
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Sign Up', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),

            // Back to Login
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
