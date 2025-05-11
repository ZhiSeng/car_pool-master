import 'package:flutter/material.dart';
import 'database_helper.dart'; // Ensure this is imported for database operations

class DriverConfirmRide extends StatefulWidget {
  final int carpoolID; // Only carpoolID is passed

  const DriverConfirmRide({Key? key, required this.carpoolID})
    : super(key: key);

  @override
  _DriverConfirmRideState createState() => _DriverConfirmRideState();
}

class _DriverConfirmRideState extends State<DriverConfirmRide> {
  String? fromLocation;
  String? toLocation;
  String? dateTime;
  int? availableSeats;
  String? ridePreference;
  bool isLoading = true; // For loading state
  final double baseFee = 2.00;
  final int baseEcoPoints = 2;

  String? username;
  String? email;

  int? seat;
  bool? musicPreference;
  bool? petFriendly;
  bool? nonSmoking;
  String? pickupNote;
  String? status;

  List<Map<String, dynamic>> rides =
      []; // List to hold the rides for this carpoolID

  @override
  void initState() {
    super.initState();
    _syncRidesAndFetchData();
  }

  // Sync rides data from Firestore to SQLite and fetch the carpool details
  Future<void> _syncRidesAndFetchData() async {
    // Sync Firestore data to SQLite first
    await DatabaseHelper.instance.syncRidesFromFirestoreToSQLite();

    // After sync, fetch carpool details and rides
    _fetchCarpoolDetails();
    _fetchRidesForCarpool();
  }

  // Fetch carpool details from the database based on carpoolID
  Future<void> _fetchCarpoolDetails() async {
    final carpool = await DatabaseHelper.instance.getCarpoolByID(
      widget.carpoolID,
    );

    if (carpool != null) {
      setState(() {
        // Concatenate date and time fields to form a full dateTime
        String date = carpool['date'] ?? 'Unknown Date';
        String time = carpool['time'] ?? 'Unknown Time';

        print(carpool);
        fromLocation =
            carpool['pickUpPoint'] ??
            'Unknown Location'; // Handle nulls with default value
        toLocation = carpool['dropOffPoint'] ?? 'Unknown Destination';
        // Combine date and time
        dateTime =
            (date != 'Unknown Date' && time != 'Unknown Time')
                ? '$date $time'
                : 'Unknown DateTime';
        availableSeats =
            carpool['availableSeats'] ?? 0; // Handle null with default 0
        ridePreference =
            carpool['ridePreference'] ?? 'No Preference'; // Handle null
        isLoading = false; // Set loading state to false after data is fetched
      });
    } else {
      // Handle case where carpool isn't found
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Carpool not found!')));
    }
  }

  // Fetch ride details from the database based on carpoolID
  Future<void> _fetchRideDetails(int carpoolID) async {
    final ride = await DatabaseHelper.instance.getRideByID(carpoolID);

    if (ride != null) {
      setState(() {
        print(ride);
        seat = ride['seat'];
        musicPreference = ride['musicPreference'] == 1;
        petFriendly = ride['petFriendly'] == 1;
        nonSmoking = ride['nonSmoking'] == 1;
        pickupNote = ride['pickupNote'] ?? 'No pickup note';
        status = ride['status'] ?? 'Unknown status';

        // Fetch user details using the userID from the ride
        _fetchUserData(ride['userID']);
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ride not found!')));
    }
  }

  // Fetch user data based on userID
  Future<void> _fetchUserData(int userID) async {
    final user = await DatabaseHelper.instance.getUserByID(userID);

    if (user != null) {
      setState(() {
        username = user['username'];
        email = user['email'];
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User not found!')));
    }
  }

  // Fetch rides for the given carpoolID from the 'rides' table
  Future<void> _fetchRidesForCarpool() async {
    final fetchedRides = await DatabaseHelper.instance.getRidesByCarpoolID(
      widget.carpoolID,
    );

    if (fetchedRides != null && fetchedRides.isNotEmpty) {
      // Filter rides by status "requested"
      final requestedRides =
          fetchedRides.where((ride) {
            return ride['status'] == 'requested' ||
                ride['status'] ==
                    'confirmed'; // Assuming "status" is the field name for ride status
          }).toList();

      setState(() {
        rides =
            requestedRides; // Update the rides list if there are rides available
      });

      // After loading rides, fetch details for each ride
      for (var ride in requestedRides) {
        final rideID =
            ride['rideID']; // Assuming rideID exists in the ride data
        _fetchRideDetails(rideID); // Pass rideID to fetch details of each ride
      }
    } else {
      setState(() {
        rides = []; // No rides found, so clear the list
      });
    }
  }

  // Function to handle Confirm and Reject Ride Actions
  Future<void> _confirmOrRejectRide(
    int rideID,
    String status,
    int seatsToReduce,
  ) async {
    try {
      // Call the confirm or reject ride method from DatabaseHelper
      await DatabaseHelper.instance.confirmOrRejectRide(
        rideID,
        status,
        seatsToReduce,
      );
      if (status == 'confirmed') {
        final carpool = await DatabaseHelper.instance.getCarpoolByID(rideID);
        final driverID = carpool?['userID'];
        double baseFee = 2.00;

        if (driverID != null) {
          // Fetch the current ecoPoints of the user
          final user = await DatabaseHelper.instance.getUserByID(driverID);
          final currentEcoPoints = user?['ecoPoints'] ?? 0;

          // Calculate new ecoPoints and fees
          final rewardPerPersonRM = baseFee * seatsToReduce;
          final updatedEcoPoints =
              currentEcoPoints +
              (2 * seatsToReduce); // 2 points for each person

          // Update the ecoPoints in the database
          await DatabaseHelper.instance.updateUserEcoPoints(
            driverID,
            updatedEcoPoints,
          );

          // Show a SnackBar to inform the user about the updated ecoPoints
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ride Confirmed! You will earn RM${rewardPerPersonRM.toStringAsFixed(2)} and +${2 * seatsToReduce} ecoPoints from this ride!',
              ),
            ),
          );
          double totalEarnings =
              rewardPerPersonRM *
              seatsToReduce; // Total earnings from passengers
        }

        final ride = await DatabaseHelper.instance.getRideByID(rideID);
        final passengerID =
            ride?['userID']; // Fetch the passenger userID from the ride table

        if (passengerID != null) {
          print('testing3');
          // Fetch the current eco points of the passenger
          final passenger = await DatabaseHelper.instance.getUserByID(
            passengerID,
          );
          final currentPassengerEcoPoints = passenger?['ecoPoints'] ?? 0;

          final updatedPassengerEcoPoints =
              currentPassengerEcoPoints +
              (seatsToReduce); // 1 point for each passenger (half of the driver's reward)

          // Update the passenger's eco points in the local database and Firestore
          await DatabaseHelper.instance.updateUserEcoPoints(
            passengerID,
            updatedPassengerEcoPoints,
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$status Ride!')));
      }
    } catch (e) {
      print('Error confirming or rejecting ride: $e');
    }
  }

  // Pull-to-refresh callback function
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true; // Set loading state to true while refreshing
    });

    // Sync rides data and fetch updated details
    await _syncRidesAndFetchData();
  }

  void _showRideDetails(
    BuildContext context,
    int rideID,
    int seat,
    String status,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.567,
          // Set the initial size (it can be adjusted)
          minChildSize: 0.567,
          // Set the minimum size (no smaller than this)
          maxChildSize: 0.567,
          // Set the maximum size (no larger than this)
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Grippy handle (drag handle)
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
                // Title for the bottom sheet
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
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        // "X" icon
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                        },
                      ),
                    ],
                  ),
                ),
                // Divider like <hr>
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
                        // Ride info
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green),
                            SizedBox(width: 10),
                            Text(
                              'From: $fromLocation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              'To: $toLocation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Date & Time: $dateTime',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Available Seats: $availableSeats',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text('Name: $username'),
                        SizedBox(height: 6),
                        Text('Email: $email'),
                        SizedBox(height: 6),
                        Text('Seat: $seat'),
                        if (status == 'confirmed') ...[
                          SizedBox(height: 6),
                          Text(
                            '🎉 You will earn RM${(baseFee * seat).toStringAsFixed(2)} and +${(baseEcoPoints * seat)} ecoPoints for this ride!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        SizedBox(height: 6),
                        Text('Music Preference: $musicPreference'),
                        SizedBox(height: 6),
                        Text('Pet Friendly: $petFriendly'),
                        SizedBox(height: 6),
                        Text('Non-smoking: $nonSmoking'),
                        SizedBox(height: 6),
                        Text(
                          'Pickup Note: ${pickupNote?.isNotEmpty ?? false ? pickupNote : 'No pickup note available'}',
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons for action
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              status == 'confirmed'
                                  ? null // Disable if confirmed
                                  : () async {
                                    await _confirmOrRejectRide(
                                      rideID,
                                      'rejected',
                                      0,
                                    );
                                    Navigator.pop(context);
                                    await _refreshData();
                                  },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey),
                          ),
                          child: Text('Reject'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              status == 'confirmed'
                                  ? null // Disable if confirmed
                                  : () async {
                                    if (availableSeats != null &&
                                        availableSeats! > 0) {
                                      await _confirmOrRejectRide(
                                        rideID,
                                        'confirmed',
                                        seat,
                                      );
                                      Navigator.pop(context);
                                      await _refreshData();
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No available seats to confirm!',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: Text('Confirm'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              status != 'confirmed'
                                  ? null
                                  : () async {
                                    await _confirmOrRejectRide(
                                      rideID,
                                      'completed',
                                      seat,
                                    );
                                    Navigator.pop(context);
                                    await _refreshData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ride Completed!'),
                                      ),
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                          ),
                          child: Text(
                            'Complete',
                            style: TextStyle(fontSize: 12),
                          ),
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
        title: Text('Confirm Ride'),
        backgroundColor: Colors.blueAccent,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator while fetching data
              : rides.isEmpty
              ? Center(
                child: Text(
                  'No rides available for this carpool.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
              : RefreshIndicator(
                onRefresh:
                    _refreshData, // This will trigger the pull-to-refresh
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12),
                      // Ride Info at the top before the card
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // From Location
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'From: $fromLocation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          // To Location
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'To: $toLocation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          // Date & Time
                          Text(
                            'Date & Time: $dateTime',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          // Available Seats
                          Text(
                            'Available Seats: $availableSeats',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                      Divider(thickness: 1),
                      // Basic Ride Info Card
                      SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: rides.length,
                        itemBuilder: (context, index) {
                          final ride = rides[index];
                          final rideID =
                              ride['rideID']; // Assuming 'rideID' is a key in the ride map
                          final seat = ride['seat'];
                          final status = ride['status'];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ride Info
                                  Text(
                                    'Name: $username',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Email: $email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Seat: $seat',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Status: $status',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  if (status == 'confirmed') ...[
                                    SizedBox(height: 8),
                                    Text(
                                      'Earn: RM${(baseFee * seat).toStringAsFixed(2)} and +${(baseEcoPoints * seat)} ecoPoints!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 8),
                                  Text(
                                    'Pickup Note: ${pickupNote?.isNotEmpty ?? false ? pickupNote : 'No pickup note available'}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Pass the rideID to the _showRideDetails method
                                        _showRideDetails(
                                          context,
                                          rideID,
                                          seat,
                                          status,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text('View Details'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
