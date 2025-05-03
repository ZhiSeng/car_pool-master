import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  final String email;

  ProfilePage({required this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController securityAnswerController = TextEditingController();

  double rating = 0.0;
  int reviewCount = 0;
  int ecoPoints = 0;

  String selectedQuestion = 'What is your pet name?';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await DatabaseHelper.instance.syncUserFromFirestore(widget.email);
    final user = await DatabaseHelper.instance.getUser(widget.email);

    if (user != null) {
      setState(() {
        usernameController.text = user['username'] ?? '';
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

      await DatabaseHelper.instance.updateUserData(widget.email, {
        'username': usernameController.text.trim(),
        'password': password,
        'security_question': selectedQuestion,
        'security_answer': securityAnswerController.text.trim(),
      });

      _showMessage("Profile updated successfully!", isSuccess: true);
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
        title: Text("My Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Editable Details", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: "Username"),
                validator: (value) => value!.isEmpty ? "Enter username" : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) => value!.isEmpty ? "Enter password" : null,
              ),
              TextFormField(
                controller: confirmPasswordController,
                decoration: InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
                validator: (value) => value!.isEmpty ? "Confirm your password" : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedQuestion,
                decoration: InputDecoration(labelText: 'Security Question'),
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
              TextFormField(
                controller: securityAnswerController,
                decoration: InputDecoration(labelText: "Security Answer"),
                validator: (value) => value!.isEmpty ? "Enter answer" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text("Save Changes"),
              ),
              Divider(height: 40),
              Text("Read-Only Info", style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                title: Text("Rating"),
                trailing: Text(rating.toStringAsFixed(1)),
              ),
              ListTile(
                title: Text("Review Count"),
                trailing: Text(reviewCount.toString()),
              ),
              ListTile(
                title: Text("Eco Points"),
                trailing: Text(ecoPoints.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
