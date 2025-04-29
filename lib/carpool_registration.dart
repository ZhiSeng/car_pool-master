import 'package:flutter/material.dart';
import 'database_helper.dart'; // Ensure correct import for your DatabaseHelper
import 'registered_carpool.dart'; // Import the Registered Carpool screen
import 'carpool_history.dart'; // Import the Carpool History screen

class CarpoolRegistrationPage extends StatefulWidget {
  @override
  _CarpoolRegistrationPageState createState() =>
      _CarpoolRegistrationPageState();
}

class _CarpoolRegistrationPageState extends State<CarpoolRegistrationPage> {
  final _pickUpController = TextEditingController();
  final _dropOffController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController();
  final _preferenceController = TextEditingController();

  int _selectedIndex = 0;

  // Function to handle navigation between pages based on the selected index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // List of pages for Bottom Navigation
  static const List<Widget> _widgetOptions = <Widget>[
    Text('Carpool Registration'), // Placeholder for Carpool Registration
    RegisteredCarpoolPage(), // Registered Carpool Page
    CarpoolHistoryPage(), // Carpool History Page
  ];

  void _submitCarpool() async {
    final pickUp = _pickUpController.text;
    final dropOff = _dropOffController.text;
    final date = _dateController.text;
    final time = _timeController.text;
    final seats = int.tryParse(_seatsController.text) ?? 0;
    final preference = _preferenceController.text;

    // Prepare data to insert into the database
    Map<String, dynamic> carpoolData = {
      'userID': 1, // Replace with actual userID
      'pickUpPoint': pickUp,
      'dropOffPoint': dropOff,
      'date': date,
      'time': time,
      'availableSeats': seats,
      'ridePreference': preference,
      'status': 'active', // Set it as active
    };

    // Insert carpool into the database
    await DatabaseHelper.instance.insertCarpool(carpoolData);

    // Optionally, navigate to another page or update the UI
    print("Carpool Registered: $pickUp to $dropOff");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carpool Registration'),
      ),
      body: _selectedIndex == 0
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _pickUpController,
              decoration: InputDecoration(labelText: 'Enter Pick-Up Point'),
            ),
            TextField(
              controller: _dropOffController,
              decoration: InputDecoration(labelText: 'Enter Drop-Off Point'),
            ),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(labelText: 'Time (HH:MM)'),
            ),
            TextField(
              controller: _seatsController,
              decoration: InputDecoration(labelText: 'Available Seats'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _preferenceController,
              decoration: InputDecoration(labelText: 'Ride Preference'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitCarpool,
              child: Text('Register Carpool'),
            ),
          ],
        ),
      )
          : _widgetOptions.elementAt(_selectedIndex), // Display appropriate page based on the selected index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Register Carpool',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Registered Carpool',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Carpool History',
          ),
        ],
      ),
    );
  }
}
