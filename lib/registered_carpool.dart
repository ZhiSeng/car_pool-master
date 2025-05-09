import 'package:flutter/material.dart';
import 'database_helper.dart';  // Ensure correct import for your DatabaseHelper
import 'driver_confirm_ride.dart';

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

  // Fetch all registered carpools for the specific user
  Future<void> _loadRegisteredCarpools() async {
    final carpoolData = await DatabaseHelper.instance.getCarpools(widget.userID);

    setState(() {
      registeredCarpools = carpoolData;
    });
  }

  // Mark carpool as completed
  void _completeCarpool(int index) async {
    final carpool = registeredCarpools[index];

    if (carpool['status'] == 'active') {
      // Set carpool status to 'completed' in the database
      await DatabaseHelper.instance.updateCarpoolStatus(carpool['id'], 'completed');

      // Add the completed carpool to the carpool history table
      await DatabaseHelper.instance.addCarpoolHistory(
        carpool['id'],
        carpool['userID'],
        'completed',
        10.0,  // Example earnings (you can calculate this based on the number of seats or other criteria)
      );

      // Reload the registered carpool list after the update
      _loadRegisteredCarpools(); // Refresh the list

      print("Carpool completed at index $index");
    } else {
      print("This carpool is not active.");
    }
  }

  // Cancel carpool (set status to 'canceled' and move it to history)
  void _cancelCarpool(int index) async {
    final carpool = registeredCarpools[index];

    if (carpool['status'] == 'active') {
      // Set carpool status to 'canceled' in the database
      await DatabaseHelper.instance.updateCarpoolStatus(carpool['id'], 'canceled');

      // Add the canceled carpool to the carpool history table
      await DatabaseHelper.instance.addCarpoolHistory(
        carpool['id'],
        carpool['userID'],
        'canceled',
        0.0,  // No earnings for canceled carpool
      );

      // Reload the registered carpool list after the update
      _loadRegisteredCarpools(); // Refresh the list

      print("Carpool canceled at index $index");
    } else {
      print("This carpool cannot be canceled.");
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
      appBar: AppBar(
        title: Text('Registered Carpools'),
      ),
      body: registeredCarpools.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: registeredCarpools.length,
        itemBuilder: (context, index) {
          final carpool = registeredCarpools[index];
          return ListTile(
            title: Text('${carpool['pickUpPoint']} → ${carpool['dropOffPoint']}'),
            subtitle: Text('Date: ${carpool['date']}, Time: ${carpool['time']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search button (opens Driver Confirm Ride Page)
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Open the Driver Confirm Ride Page for the current carpool
                    _openDriverConfirmRidePage(carpool['id']);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: carpool['status'] == 'active'
                      ? () => _completeCarpool(index) // Mark as completed
                      : null,  // Only allow completing if active
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: carpool['status'] == 'active'
                      ? () => _cancelCarpool(index)  // Mark as canceled
                      : null,  // Only allow canceling if active
                ),
              ],
            ),
            tileColor: carpool['status'] == 'active' ? Colors.green[100] : Colors.grey[300],
          );
        },
      ),
    );
  }
}