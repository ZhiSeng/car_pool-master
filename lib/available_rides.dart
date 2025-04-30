import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

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
    activeCarpools = _fetchActiveCarpools();
  }

  Future<List<Map<String, dynamic>>> _fetchActiveCarpools() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    int userID = 1; // Replace with actual user ID in real app
    List<Map<String, dynamic>> allRides = await dbHelper.getCarpools(userID);

    return allRides.where((ride) {
      bool locationMatch = ride['pickUpPoint'] == widget.fromLocation &&
          ride['dropOffPoint'] == widget.toLocation;

      bool preferenceMatch = true;
      if (widget.musicPreference) {
        preferenceMatch &= ride['ridePreference']?.contains('Music') ?? false;
      }
      if (widget.petFriendly) {
        preferenceMatch &= ride['ridePreference']?.contains('Pet') ?? false;
      }
      if (widget.nonSmoking) {
        preferenceMatch &= ride['ridePreference']?.contains('Non-Smoking') ?? false;
      }

      bool seatAvailable = ride['availableSeats'] >= widget.seatCount;

      return locationMatch && preferenceMatch && seatAvailable;
    }).toList();
  }

  String _formatDateTime(String date, String time) {
    try {
      final formatted = '$date ${time.split(':')[0].padLeft(2, '0')}:${time.split(':')[1].padLeft(2, '0')}';
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(formatted));
    } catch (e) {
      return 'Invalid Date/Time';
    }
  }

  void _showRideDetailsSheet(BuildContext context, Map<String, dynamic> carpool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Confirm Ride',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                    Icon(Icons.radio_button_checked, color: Colors.green),
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
                                    Text('From', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(carpool['pickUpPoint'], style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 8),
                                    Text('To', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(carpool['dropOffPoint'], style: TextStyle(fontSize: 16)),
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
                        if (carpool['ridePreference'] != null && carpool['ridePreference'].toString().isNotEmpty)
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

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ride requested successfully!')),
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

                    return ListView.builder(
                      itemCount: carpools.length,
                      itemBuilder: (context, index) {
                        var carpool = carpools[index];

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From: ${carpool['pickUpPoint']}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'To: ${carpool['dropOffPoint']}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Date & Time: ${_formatDateTime(carpool['date'], carpool['time'])}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.green[700]),  // Person icon for each available seat
                                    SizedBox(width: 6),
                                    Text(
                                      '× ${carpool['availableSeats']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                if (carpool['ridePreference'] != null && carpool['ridePreference'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Preference: ${carpool['ridePreference']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
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
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
