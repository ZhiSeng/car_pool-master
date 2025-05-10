import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'carpool_main_page.dart';
import 'registration_screen.dart';
import 'retrieve_password_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);  // Added Key parameter

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Boolean to toggle password visibility
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.syncAllUsersFromFirestore();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminLoginScreen()),
      );
    }
  }

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        _showMessage('Please fill in both fields');
      }
      return;
    }

    final user = await DatabaseHelper.instance.getUser(email);
    if (user != null && user['password'] == password) {
      if (mounted) {
        _showMessage('Login Successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CarpoolMainPage(userID: user['userID']),
          ),
        );
      }
    } else {
      if (mounted) {
        _showMessage('Invalid email or password. Please try again.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Color(0xFF1976D2), // Match the Find Ride theme
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
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
              obscureText: !_isPasswordVisible, // Toggle password visibility
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
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
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

            // Login Button
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Consistent button color
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Login', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),

            // Sign Up and Forgot Password
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text("Don't have an account? Sign up"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RetrievePasswordScreen()),
                );
              },
              child: Text("Forgot Password?"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'User Login',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin Login',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFF1976D2), // Matching color with app theme
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
    );
  }
}
