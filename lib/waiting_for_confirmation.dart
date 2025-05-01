import 'package:flutter/material.dart';
import 'database_helper.dart';

class WaitingForConfirmationPage extends StatefulWidget {
  final int carpoolID;
  final int userID;

  const WaitingForConfirmationPage({
    required this.carpoolID,
    required this.userID,
  });

  @override
  _WaitingForConfirmationPageState createState() =>
      _WaitingForConfirmationPageState();
}

class _WaitingForConfirmationPageState
    extends State<WaitingForConfirmationPage> {
  bool isConfirmed = false;
  bool isExpired = false;
  bool isCancelled = false;
  late DateTime requestTime;

  @override
  void initState() {
    super.initState();
    requestTime = DateTime.now();
    _startExpirationTimer();
  }

  void _startExpirationTimer() async {
    // Wait for 3 minutes before checking for expiration
    await Future.delayed(Duration(minutes: 3));

    if (!isCancelled && !isConfirmed) {
      bool dbResult = await _expireRideInDatabase();
      setState(() {
        isExpired = dbResult;
      });

      if (!dbResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update expiration in database.')),
        );
      }
    }
  }

  void _cancelRideRequest() async {
    setState(() {
      isCancelled = true;
    });

    bool result = await _cancelRideInDatabase();
    if (!result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel the ride.')),
      );
    }
    // Show back button either way
  }

  Future<bool> _cancelRideInDatabase() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    return await dbHelper.cancelRide(widget.carpoolID, widget.userID);
  }

  Future<bool> _expireRideInDatabase() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    return await dbHelper.expireRide(widget.carpoolID, widget.userID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waiting for ride Confirmation'),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isExpired || isCancelled)
              Icon(Icons.error, color: Colors.redAccent, size: 80)
            else
              CircularProgressIndicator(),
            SizedBox(height: 20),
            if (isExpired)
              Text(
                'Your ride request has expired.',
                style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
              )
            else if (isCancelled)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                'You have cancelled the ride request. Please try again.',
                style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                ),
              )
    else
              Column(
                children: [
                  Text(
                    'Your ride request is pending confirmation.',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Please wait while drivers process your request.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            SizedBox(height: 30),
            if (isExpired || isCancelled)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text('Back'),
              )
            else
              ElevatedButton(
                onPressed: _cancelRideRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text('Cancel Ride'),
              ),
          ],
        ),
      ),
    );
  }
}
