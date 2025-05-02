import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'waiting_for_confirmation.dart';

class AvailableRidesPage extends StatefulWidget {
  final String fromLocation;
  final String toLocation;
  final int seatCount;
  final bool musicPreference;
  final bool petFriendly;
  final bool nonSmoking;

  const AvailableRidesPage({
    required this.fromLocation,
    required this.toLocation,
    required this.seatCount,
    required this.musicPreference,
    required this.petFriendly,
    required this.nonSmoking,
  });

  @override
  _AvailableRidesPageState createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  late Future<List<Map<String, dynamic>>> activeCarpools;

  @override
  void initState() {
    super.initState();
    activeCarpools = Future.value([]);
    _syncDataAndFetchRides();
  }

  // Sync Firestore data and then fetch rides from SQLite
  Future<List<Map<String, dynamic>>> _syncDataAndFetchRides() async {
    // First, update SQLite with Firestore data
    await DatabaseHelper.instance.updateSQLiteFromFirestore();

    // Then fetch active rides from SQLite based on user preferences
    List<Map<String, dynamic>> rides = await DatabaseHelper.instance.getActiveCarpools(
      fromLocation: widget.fromLocation,
      toLocation: widget.toLocation,
      seatCount: widget.seatCount,
      musicPreference: widget.musicPreference,
      petFriendly: widget.petFriendly,
      nonSmoking: widget.nonSmoking,
    );

    setState(() {
      activeCarpools = Future.value(rides);
    });

    return rides;
  }

  String _formatDateTime(String date, String time) {
    try {
      final formatted =
          '$date ${time.split(':')[0].padLeft(2, '0')}:${time.split(':')[1].padLeft(2, '0')}';
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(formatted));
    } catch (e) {
      return 'Invalid Date/Time';
    }
  }

  void _showRideDetailsSheet(
    BuildContext context,
    Map<String, dynamic> carpool,
  ) {
    TextEditingController pickupNoteController = TextEditingController();

    // Ensure carpoolID is not null
    int? carpoolID = carpool['id']; // Replace with your actual field name

    if (carpoolID == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: Invalid ride details')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Grippy handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Top bar with title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Confirm Ride',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.directions_car, color: Colors.blueAccent),
                    ],
                  ),
                ),

                // Horizontal divider (like <hr>)
                Divider(thickness: 1),

                // Ride details scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      Icons.radio_button_checked,
                                      color: Colors.green,
                                    ),
                                    Container(
                                      height: 30,
                                      width: 2,
                                      color: Colors.grey,
                                    ),
                                    Icon(Icons.location_on, color: Colors.red),
                                  ],
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      carpool['pickUpPoint'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'To',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      carpool['dropOffPoint'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Date & Time: ${_formatDateTime(carpool['date'], carpool['time'])}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Available Seats: ${carpool['availableSeats']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (carpool['ridePreference'] != null &&
                            carpool['ridePreference'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              'Preference: ${carpool['ridePreference']}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup Note',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: pickupNoteController,
                        keyboardType: TextInputType.text,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Enter additional pickup instructions...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey),
                          ),
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            DatabaseHelper dbHelper = DatabaseHelper.instance;
                            int userID =
                                1; // replace with the current logged-in passenger's userID
                            String pickupNote =
                                pickupNoteController.text.trim();

                            print(carpoolID);
                            print(userID);
                            print(pickupNote);

                            // Request the ride
                            String result = await dbHelper.requestRide(
                              carpoolID,
                              userID,
                              pickupNote: pickupNote,
                            );

                            // Show result
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(result)));

                            // Close bottom sheet before navigating
                            Navigator.pop(context);

                            // Then navigate
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WaitingForConfirmationPage(
                                      carpoolID: carpoolID,
                                      userID: userID,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _refreshCarpools() async {
    List<Map<String, dynamic>> newCarpools = await _syncDataAndFetchRides();
    setState(() {
      activeCarpools = Future.value(newCarpools);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Rides'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: activeCarpools,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No matching rides found.'));
                  } else {
                    List<Map<String, dynamic>> carpools = snapshot.data!;

                     return RefreshIndicator(
                       onRefresh: _refreshCarpools,
                       child:
                      ListView.builder(
                        itemCount: carpools.length,
                        itemBuilder: (context, index) {
                          var carpool = carpools[index];

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From: ${carpool['pickUpPoint']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'To: ${carpool['dropOffPoint']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Date & Time: ${_formatDateTime(
                                        carpool['date'], carpool['time'])}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  if (carpool['ridePreference'] != null &&
                                      carpool['ridePreference']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Preference: ${carpool['ridePreference']}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Colors.green[700],
                                      ),
                                      // Person icon for each available seat
                                      SizedBox(width: 6),
                                      Text(
                                        '× ${carpool['availableSeats']}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        _showRideDetailsSheet(context, carpool);
                                      },
                                      child: Text('Request Ride'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      )
                      );
                    };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
