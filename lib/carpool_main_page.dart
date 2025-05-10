import 'package:flutter/material.dart';
import 'carpool_registration.dart';
import 'database_helper.dart';
import 'profile_page.dart';
import 'rate_review_list_page.dart';
import 'find_a_ride.dart';
import 'eco_points_voucher_page.dart';

class CarpoolMainPage extends StatefulWidget {
  final int userID;

  CarpoolMainPage({required this.userID});

  @override
  _CarpoolMainPageState createState() => _CarpoolMainPageState();
}

class _CarpoolMainPageState extends State<CarpoolMainPage> {
  String username = "";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _syncRides();
  }

  Future<void> _loadUsername() async {
    final user = await DatabaseHelper.instance.getUserByID(widget.userID);
    if (user != null) {
      setState(() {
        username = user['username'];
      });
    }
  }

  // Function to sync rides from Firestore to SQLite
  Future<void> _syncRides() async {
    await DatabaseHelper.instance.syncRidesFromFirestoreToSQLite();
  }

  // Function to handle Bottom Navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carpool Main Page'),
        backgroundColor: Colors.blueAccent, // Same as Find a Ride
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userID: widget.userID),
                  ),
                ).then((_) {
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
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Background color like the login screen
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              // Align items at the top of the screen
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Text - Move it up
                SizedBox(height: 60), // Adjust height here to move text up
                Text(
                  'TARUMT Ride',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                ),
                Text(
                  'Welcome to carpool App!',
                  style: TextStyle(fontSize: 28, color: Colors.blue.shade700),
                ),
                SizedBox(height: 100), // Adjusted height for better visual spacing

                // Register Carpool Button (Less rounded and thicker)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CarpoolRegistrationPage(userID: widget.userID),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Button color
                    minimumSize: Size(double.infinity, 60), // Thicker buttons
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Less rounded corners
                    ),
                  ),
                  child: Text('Register a Carpool', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),

                // Find a Ride Button (Less rounded and thicker)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FindARidePage(userID: widget.userID),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Button color
                    minimumSize: Size(double.infinity, 60), // Thicker buttons
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Less rounded corners
                    ),
                  ),
                  child: Text('Find a Ride', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),

                // Rate & Review Button (Less rounded and thicker)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RateReviewListPage(userID: widget.userID),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Button color
                    minimumSize: Size(double.infinity, 60), // Thicker buttons
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Less rounded corners
                    ),
                  ),
                  child: Text('Rate & Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EcoPointsAndVoucherPage(userID: widget.userID),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text('EcoPoints & Vouchers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

