import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:async';

class WaitingForConfirmationPage extends StatefulWidget {
  final int rideID;
  final int carpoolID;
  final int userID;

  const WaitingForConfirmationPage({
    required this.rideID,
    required this.carpoolID,
    required this.userID,
  });

  @override
  _WaitingForConfirmationPageState createState() =>
      _WaitingForConfirmationPageState();
}

class _WaitingForConfirmationPageState
    extends State<WaitingForConfirmationPage> {
  bool isRejected = false;
  bool isConfirmed = false;
  bool isExpired = false;
  bool isCancelled = false;
  late DateTime requestTime;
  late Timer _statusCheckTimer;
  Map<String, dynamic>? carpoolDetails;
  bool isLoadingDetails = false;
  Map<String, dynamic>? driverDetails;

  @override
  void initState() {
    super.initState();
    requestTime = DateTime.now();
    _startStatusCheck();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _statusCheckTimer.cancel();
    super.dispose();
  }

  void _startStatusCheck() {
    // Start a periodic check every 5 seconds
    _statusCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      // Check the current status from the database
      _checkRideStatus();
    });

    // Also, start expiration timer to handle ride expiration logic
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

  void _checkRideStatus() async {
    await DatabaseHelper.instance.syncRidesFromFirestoreToSQLite();
    // Get the current status from the database
    String status = await DatabaseHelper.instance.checkRideStatus(
      widget.rideID,
      widget.carpoolID,
      widget.userID,
    );

    if (status == 'confirmed') {
      setState(() {
        isConfirmed = true;
        isRejected = false;
        isExpired = false;
      });
      await _fetchCarpoolDetails();
    } else if (status == 'rejected') {
      setState(() {
        isRejected = true;
        isConfirmed = false;
        isExpired = false;
      });
    } else if (status == 'expired') {
      setState(() {
        isExpired = true;
        isConfirmed = false;
        isRejected = false;
      });
    }

    if (isConfirmed || isRejected || isExpired) {
      _statusCheckTimer
          .cancel(); // Stop checking once confirmed, rejected, or expired
    }
  }

  void _cancelRideRequest() async {
    setState(() {
      isCancelled = true;
    });

    bool result = await _cancelRideInDatabase();
    if (!result) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel the ride.')));
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

  Future<void> _fetchCarpoolDetails() async {
    setState(() {
      isLoadingDetails = true;
    });

    // Fetch from your local DB (or Firestore if needed)
    Map<String, dynamic>? details = await DatabaseHelper.instance
        .getCarpoolByID(widget.carpoolID);

    setState(() {
      carpoolDetails = details;
      isLoadingDetails = false;
    });

    if (details != null && details['userID'] != null) {
      await _fetchDriverDetails(details['userID']);
    }
  }

  Future<void> _fetchDriverDetails(int userID) async {
    final result = await DatabaseHelper.instance.getUserByID(userID);
    setState(() {
      driverDetails = result;
    });
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
            else if (isConfirmed)
              Icon(Icons.check_circle, color: Colors.green, size: 80)
            else if (isRejected)
              Icon(Icons.cancel, color: Colors.red, size: 80)
            else
              CircularProgressIndicator(),
            SizedBox(height: 20),
            if (isExpired)
              Text(
                'Your ride request has expired.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
            else if (isCancelled)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'You have cancelled the ride request. Please try again.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (isConfirmed)
              // Show confirmed message
              Column(
                children: [
                  Text(
                    'Your ride request has been confirmed!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  if (isLoadingDetails)
                    CircularProgressIndicator()
                  else if (carpoolDetails != null)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Driver Name: ${driverDetails!['username']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Driver Rate: ${driverDetails!['rating']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Car Plate: ${carpoolDetails!['carPlateNumber']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Car Color: ${carpoolDetails!['carColor']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Car Type: ${carpoolDetails!['carModel']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Driver will arrive to pickup point as soon as possible, please get ready at the pickup point.',
                          style:  TextStyle(fontSize: 16, color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                    ),
                ],
              )
            else if (isRejected)
              // Show rejected status
              Text(
                'Your ride request has been rejected.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
            else
              Column(
                children: [
                  Text(
                    'Your ride request is pending confirmation.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Please wait while drivers process your request.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            SizedBox(height: 30),
            if (isExpired || isCancelled || isConfirmed || isRejected)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text('Back', style: TextStyle(color: Colors.white)),
              )
            else
              ElevatedButton(
                onPressed: _cancelRideRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text(
                  'Cancel Ride',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
