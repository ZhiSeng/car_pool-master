import 'package:flutter/material.dart';
import 'database_helper.dart';  // Ensure correct import for your DatabaseHelper
import 'driver_confirm_ride.dart';  // Assuming you have a DriverConfirmRide page

class RegisteredCarpoolPage extends StatefulWidget {
  final int userID;

  const RegisteredCarpoolPage({Key? key, required this.userID}) : super(key: key);

  @override
  _RegisteredCarpoolPageState createState() => _RegisteredCarpoolPageState();
}

class _RegisteredCarpoolPageState extends State<RegisteredCarpoolPage> {
  List<Map<String, dynamic>> registeredCarpools = [];

  @override
  void initState() {
    super.initState();
    _loadRegisteredCarpools();
  }

  // Fetch all registered carpools for the specific user (active status)
  void _loadRegisteredCarpools() async {
    // Ensure Firestore data is synced to SQLite
    await DatabaseHelper.instance.syncCarpoolsFromFirestoreToSQLite();

    // Now fetch the carpool data from SQLite and filter out non-active carpools
    final carpoolData = await DatabaseHelper.instance.getCarpools(widget.userID);

    setState(() {
      registeredCarpools = carpoolData.where((carpool) => carpool['status'] == 'active').toList();
    });
  }

  // Show confirmation dialog to confirm carpool completion or cancellation
  Future<void> _showConfirmationDialog(String carpoolID, String action) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to mark this carpool as $action?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                // If the user confirms, update the status to 'inactive' in Firestore and SQLite
                _updateCarpoolStatus(carpoolID, action); // Pass carpoolID as String
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }


  // Update carpool status to 'inactive'
  Future<void> _updateCarpoolStatus(String firestoreCarpoolID, String action) async {
    try {
      // 1. Update Firestore status to 'inactive' (or completed/canceled)
      await DatabaseHelper.instance.updateCarpoolStatusToInactive(firestoreCarpoolID);

      // 2. Re-sync Firestore -> SQLite to reflect the updated data
      await DatabaseHelper.instance.syncCarpoolsFromFirestoreToSQLite();

      // 3. Get the updated local SQLite carpool using Firestore ID
      final carpool = await DatabaseHelper.instance.getCarpoolByFirestoreID(firestoreCarpoolID);

      if (carpool != null) {
        final localCarpoolID = carpool['id'] as int;

        // 4. Add to local history table using local carpool ID
        await DatabaseHelper.instance.addCarpoolHistoryToFirestore(
          firestoreCarpoolID,
          widget.userID,
          action,
          action == 'completed' ? await DatabaseHelper.instance.calculateDriverEarnings(localCarpoolID) : 0.0,
        );

// Immediately sync latest history from Firestore to SQLite
        await DatabaseHelper.instance.syncCarpoolHistoryFromFirestoreToSQLite(widget.userID);

      }

      // 5. Show success and reload display from local
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carpool marked as $action')),
      );
      _loadRegisteredCarpools();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update carpool status')),
      );
    }
  }

  void _completeCarpool(int index) async {
    final carpool = registeredCarpools[index];
    final carpoolID = carpool['id'];

    // Ensure there are no requested rides before completing the carpool
    bool hasRequested = await DatabaseHelper.instance.hasRideStatus(carpoolID, 'requested');

    if (hasRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot complete: There are passengers who have requested but not accepted or rejected.')),
      );
      return; // Exit the function without completing the carpool
    }

    // Ensure no confirmed passenger has incomplete ride
    bool hasPending = await DatabaseHelper.instance.hasUncompletedConfirmedRides(carpoolID);

    if (hasPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot complete: Some confirmed passengers have not completed their ride.')),
      );
      return; // Exit the function without completing the carpool
    }

    // Proceed with completing the carpool
    if (carpool['status'] == 'active') {
      _showConfirmationDialog(carpool['firestoreID'], 'completed');

      // Update earnings in the carpool table after completing
      await DatabaseHelper.instance.updateCarpoolEarnings(carpoolID);
    }
  }


  void _cancelCarpool(int index) async {
    final carpool = registeredCarpools[index];
    final carpoolID = carpool['id'];

    // Check if there are any requested or confirmed passengers
    bool hasRequested = await DatabaseHelper.instance.hasRideStatus(carpoolID, 'requested');
    bool hasConfirmed = await DatabaseHelper.instance.hasRideStatus(carpoolID, 'confirmed');

    if (hasRequested || hasConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot cancel: There are passengers who requested or were accepted.')),
      );
      return;
    }

    // Proceed with cancellation
    if (carpool['status'] == 'active') {
      _showConfirmationDialog(carpool['firestoreID'], 'canceled');
    }
  }

  // Navigate to Driver Confirm Ride Page
  void _openDriverConfirmRidePage(int carpoolID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverConfirmRide(carpoolID: carpoolID),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes back button
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          'Registered Carpool',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: registeredCarpools.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: registeredCarpools.length,
          itemBuilder: (context, index) {
            final carpool = registeredCarpools[index];
            final isActive = carpool['status'] == 'active';

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${carpool['pickUpPoint']} → ${carpool['dropOffPoint']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            carpool['status'].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Date: ${carpool['date']}'),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Time: ${carpool['time']}'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.blueAccent),
                          tooltip: 'View Ride Requests',
                          onPressed: () => _openDriverConfirmRidePage(carpool['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          tooltip: 'Mark as Completed',
                          onPressed: isActive ? () => _completeCarpool(index) : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Cancel Carpool',
                          onPressed: isActive ? () => _cancelCarpool(index) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
