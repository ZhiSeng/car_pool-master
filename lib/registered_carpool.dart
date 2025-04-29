import 'package:flutter/material.dart';
import 'database_helper.dart';  // Ensure correct import for your DatabaseHelper

class RegisteredCarpoolPage extends StatefulWidget {
  const RegisteredCarpoolPage({Key? key}) : super(key: key);

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

  // Fetch all registered carpools
  Future<void> _loadRegisteredCarpools() async {
    int userID = 1;  // Replace with actual userID
    final carpoolData = await DatabaseHelper.instance.getCarpools(userID);

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
