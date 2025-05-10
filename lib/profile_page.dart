import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final int userID;

  ProfilePage({required this.userID});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController securityAnswerController = TextEditingController();

  double rating = 0.0;
  int reviewCount = 0;
  int ecoPoints = 0;

  String selectedQuestion = 'What is your pet name?';

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseHelper.instance.getUserByID(widget.userID);

    if (user != null) {
      setState(() {
        usernameController.text = user['username'] ?? '';
        emailController.text = user['email'] ?? '';
        passwordController.text = user['password'] ?? '';
        securityAnswerController.text = user['security_answer'] ?? '';
        selectedQuestion = user['security_question'] ?? selectedQuestion;

        rating = (user['rating'] ?? 0.0).toDouble();
        reviewCount = user['reviewCount'] ?? 0;
        ecoPoints = user['ecoPoints'] ?? 0;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      String password = passwordController.text.trim();
      String confirmPassword = confirmPasswordController.text.trim();

      if (password != confirmPassword) {
        _showMessage("Passwords do not match!");
        return;
      }

      // Prepare data to update
      Map<String, dynamic> updates = {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'password': password,
        'security_question': selectedQuestion,
        'security_answer': securityAnswerController.text.trim(),
      };

      // Update data in SQLite
      await DatabaseHelper.instance.updateUserData(widget.userID.toString(), updates);

      // Now update Firestore directly using the userID
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userID', isEqualTo: widget.userID)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Firestore update
        final docRef = snapshot.docs.first.reference;
        await docRef.update({
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'password': password,
          'security_question': selectedQuestion,
          'security_answer': securityAnswerController.text.trim(),
        });

        _showMessage("Profile updated successfully!", isSuccess: true);
      } else {
        _showMessage("User not found in Firestore.");
      }
    }
  }

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
        title: Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Ensure the IconButton for logout is placed correctly
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Editable Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              _buildTextFormField(usernameController, "Username"),
              _buildTextFormField(emailController, "Email"),
              _buildPasswordFormField(passwordController, "Password", _isPasswordVisible),
              _buildPasswordFormField(confirmPasswordController, "Confirm Password", _isConfirmPasswordVisible),
              _buildDropdownMenu(),
              _buildTextFormField(securityAnswerController, "Security Answer"),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text("Save Changes"),
              ),

              Divider(height: 40),
              Text("Read-Only Info", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              _buildReadOnlyTile("Rating", rating.toStringAsFixed(1)),
              _buildReadOnlyTile("Review Count", reviewCount.toString()),
              _buildReadOnlyTile("Eco Points", ecoPoints.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget _buildPasswordFormField(TextEditingController controller, String label, bool visibility) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: !visibility,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              visibility ? Icons.visibility : Icons.visibility_off,
              color: Colors.blueAccent,
            ),
            onPressed: () {
              setState(() {
                visibility = !visibility;
              });
            },
          ),
        ),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: selectedQuestion,
        decoration: InputDecoration(
          labelText: "Security Question",
          labelStyle: TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
        items: [
          'What is your pet name?',
          'What is your mother\'s maiden name?',
          'What was your first school?'
        ].map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
        onChanged: (value) {
          setState(() {
            selectedQuestion = value!;
          });
        },
      ),
    );
  }

  Widget _buildReadOnlyTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: ListTile(
        title: Text(label),
        trailing: Text(value),
      ),
    );
  }
}
