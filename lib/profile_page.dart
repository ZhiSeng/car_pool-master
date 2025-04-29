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
  bool isEditing = false;
  bool isPasswordVisible = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController securityAnswerController = TextEditingController();

  String selectedQuestion = '';
  int ecoPoints = 0;
  double rating = 0.0;
  int reviewCount = 0;

  final List<String> securityQuestions = [
    'What is your pet name?',
    'What is your mother\'s maiden name?',
    'What was your first school?'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseHelper.instance.getUser(widget.email);
    if (user != null) {
      setState(() {
        usernameController.text = user['username'];
        passwordController.text = user['password'];
        emailController.text = user['email'];
        selectedQuestion = user['security_question'];
        securityAnswerController.text = user['security_answer'];
        ecoPoints = user['ecoPoints'] ?? 0;
        rating = user['rating']?.toDouble() ?? 0.0;
        reviewCount = user['reviewCount'] ?? 0;
      });
    }
  }

  Future<void> _saveUserData() async {
    await DatabaseHelper.instance.updateUserData(
      emailController.text.trim(),
      {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'security_question': selectedQuestion,
        'security_answer': securityAnswerController.text.trim(),
      },
    );
    setState(() {
      isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveUserData();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildInfoRow(Icons.person, 'Username:', TextField(
              controller: usernameController,
              enabled: isEditing,
              decoration: InputDecoration(border: InputBorder.none),
            )),
            _buildInfoRow(Icons.lock, 'Password:', Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    enabled: isEditing,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: isEditing
                      ? () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  }
                      : null,
                ),
              ],
            )),
            _buildInfoRow(Icons.email, 'Email:', TextField(
              controller: emailController,
              enabled: isEditing,
              decoration: InputDecoration(border: InputBorder.none),
            )),
            _buildInfoRow(Icons.help_outline, 'Secret Question:', isEditing
                ? DropdownButton<String>(
              isExpanded: true,
              value: selectedQuestion,
              onChanged: (value) {
                setState(() {
                  selectedQuestion = value!;
                });
              },
              items: securityQuestions.map((question) {
                return DropdownMenuItem(
                  value: question,
                  child: Text(question),
                );
              }).toList(),
            )
                : Text(selectedQuestion)),
            _buildInfoRow(Icons.edit, 'Secret Answer:', TextField(
              controller: securityAnswerController,
              enabled: isEditing,
              decoration: InputDecoration(border: InputBorder.none),
            )),

            Divider(thickness: 1),

            _buildInfoRow(Icons.eco, 'Eco Point(s):', Text('$ecoPoints')),
            _buildInfoRow(Icons.star, 'Rate(s):', Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating.round() ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                );
              }),
            )),
            _buildInfoRow(Icons.comment, 'Review(s):', Text('$reviewCount')),

            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              },
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          SizedBox(width: 8),
          Container(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: content),
        ],
      ),
    );
  }
}
