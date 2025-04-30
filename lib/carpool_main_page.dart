import 'package:flutter/material.dart';
import 'carpool_registration.dart';
import 'database_helper.dart';
import 'profile_page.dart';
import 'rate_review_list_page.dart';
import 'find_a_ride.dart';


class CarpoolMainPage extends StatefulWidget {
  final String email;

  CarpoolMainPage({required this.email});

  @override
  _CarpoolMainPageState createState() => _CarpoolMainPageState();
}

class _CarpoolMainPageState extends State<CarpoolMainPage> {
  String username = "";

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = await DatabaseHelper.instance.getUser(widget.email);
    if (user != null) {
      setState(() {
        username = user['username'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carpool Main Page'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(email: widget.email),
                  ),
                ).then((_) {
                  // ✅ Refresh username after returning from ProfilePage
                  _loadUsername();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  username.isNotEmpty ? username : '...',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Carpool App!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CarpoolRegistrationPage()),
                );
              },
              child: Text('Register a Carpool'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindARidePage()),
                );
              },
              child: Text('Find a Ride'), // Button for FindARidePage
            ),
            ElevatedButton(
              onPressed: () async {
                final user = await DatabaseHelper.instance.getUser(widget.email);
                if (user != null) {
                  int userID = user['userID'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RateReviewListPage(userID: userID),
                    ),
                  );
                }
              },
              child: Text('Rate & Review'),
            ),
          ],
        ),
      ),
    );
  }
}
