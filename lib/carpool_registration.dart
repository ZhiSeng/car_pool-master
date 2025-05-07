import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth import
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
  final _carPlateController = TextEditingController();  // Car Plate TextField
  final _carColorController = TextEditingController();  // Car Color TextField
  final _carModelController = TextEditingController();  // Car Model TextField

  // Dropdown list for pick-up and drop-off points
  final List<String> locations = [
    'East Campus Gate',
    'TARUMT Main Gate',
    'PV9',
    'PV15',
    'Setapak Central Mall',
    'PV10',
    'PV12',
  ];

  String _selectedPickUp = 'East Campus Gate';
  String _selectedDropOff = 'TARUMT Main Gate';

  // For checking the preferences
  bool _musicPreference = false;
  bool _petFriendly = false;
  bool _nonSmoking = false;

  int _availableSeats = 1; // Start from 1 seat

  int _selectedIndex = 0;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  // Function to handle navigation between pages based on the selected index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Get the current user on page load
    _currentUser = _auth.currentUser;
  }

  // List of pages for Bottom Navigation
  static const List<Widget> _widgetOptions = <Widget>[
    Text('Carpool Registration'), // Placeholder for Carpool Registration
    RegisteredCarpoolPage(), // Registered Carpool Page
    CarpoolHistoryPage(), // Carpool History Page
  ];

  // Function to open date picker (only future dates)
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    DateTime pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate, // Restrict to future dates (today and beyond)
      lastDate: DateTime(2101),
    ) ?? initialDate;

    setState(() {
      _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];  // YYYY-MM-DD
    });
  }

  // Function to open time picker (only future times)
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();
    // Ensure future time selection
    TimeOfDay pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    ) ?? initialTime;

    // Check if the selected time is in the future
    DateTime now = DateTime.now();
    DateTime selectedDateTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);

    if (selectedDateTime.isBefore(now)) {
      // Adjust time to future if selected time is in the past
      selectedDateTime = selectedDateTime.add(Duration(minutes: 1)); // Add 1 minute to ensure future time

      // Update the time picker to reflect future time
      pickedTime = TimeOfDay.fromDateTime(selectedDateTime);
    }

    setState(() {
      _timeController.text = "${pickedTime.format(context)}";  // HH:MM AM/PM
    });
  }

  // Validation function
  String? _validateForm() {
    if (_selectedPickUp.isEmpty) {
      return "Pick-Up Point is required.";
    }
    if (_selectedDropOff.isEmpty) {
      return "Drop-Off Point is required.";
    }
    if (_dateController.text.isEmpty || DateTime.parse(_dateController.text).isBefore(DateTime.now())) {
      return "Please select a future date.";
    }
    if (_timeController.text.isEmpty || DateTime.now().isAfter(DateTime.now().add(Duration(hours: 1)))) {
      return "Please select a future time.";
    }
    if (_availableSeats < 1) {
      return "Available Seats must be at least 1.";
    }
    if (_carPlateController.text.isEmpty) {
      return "Car Plate Number is required.";
    }
    if (_carColorController.text.isEmpty) {
      return "Car Color is required.";
    }
    if (_carModelController.text.isEmpty) {
      return "Car Model is required.";
    }
    return null;
  }

  // Show alert dialog after successful registration
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Registration Successful'),
          content: Text('Your carpool has been successfully registered!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to submit carpool details
  void _submitCarpool() async {
    String? validationMessage = _validateForm();
    if (validationMessage != null) {
      // If validation fails, show an error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    if (_currentUser == null) {
      // If no user is logged in, show an error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not logged in.")));
      return;
    }

    final pickUp = _selectedPickUp;
    final dropOff = _selectedDropOff;
    final date = _dateController.text;
    final time = _timeController.text;
    final seats = _availableSeats;
    final preference = [
      if (_musicPreference) 'Music Preference',
      if (_petFriendly) 'Pet Friendly',
      if (_nonSmoking) 'Non-Smoking'
    ].join(', ');

    final carPlate = _carPlateController.text;  // Car Plate number
    final carColor = _carColorController.text;  // Car Color
    final carModel = _carModelController.text;  // Car Model

    // Prepare data to insert into the database
    Map<String, dynamic> carpoolData = {
      'userID': _currentUser!.uid, // Use the current user's UID
      'pickUpPoint': pickUp,
      'dropOffPoint': dropOff,
      'date': date,
      'time': time,
      'availableSeats': seats,
      'ridePreference': preference,
      'status': 'active', // Set it as active
      'carPlateNumber': carPlate,  // Store car plate number
      'carColor': carColor,        // Store car color
      'carModel': carModel,        // Store car model
    };

    // Insert carpool into the database
    await DatabaseHelper.instance.insertCarpool(carpoolData);

    // Show success dialog after successful registration
    _showSuccessDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carpool Registration'),
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(  // Make the content scrollable to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pick-Up Point Dropdown with Label aligned left
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Pick-Up Point', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedPickUp,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPickUp = newValue!;
                        });
                      },
                      items: locations.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              // Drop-Off Point Dropdown with Label aligned left
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Drop-Off Point', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedDropOff,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDropOff = newValue!;
                        });
                      },
                      items: locations.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              // Date Picker with Label
              SizedBox(height: 12),
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                    labelText: 'Select Date',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    )),
              ),

              // Time Picker with Label
              SizedBox(height: 12),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                    labelText: 'Select Time',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: () => _selectTime(context),
                    )),
              ),

              // Available Seats (Stepper to adjust the number) with Label
              SizedBox(height: 12),
              Text('Available Seats:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (_availableSeats > 1) _availableSeats--;
                      });
                    },
                  ),
                  Text('$_availableSeats'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _availableSeats++;
                      });
                    },
                  ),
                ],
              ),

              // Car Information Fields with Labels
              SizedBox(height: 12),
              TextField(
                controller: _carPlateController,
                decoration: InputDecoration(labelText: 'Enter Car Plate Number'),
              ),
              TextField(
                controller: _carColorController,
                decoration: InputDecoration(labelText: 'Enter Car Color'),
              ),
              TextField(
                controller: _carModelController,
                decoration: InputDecoration(labelText: 'Enter Car Model'),
              ),

              // Ride Preferences (Checkboxes) with Label
              SizedBox(height: 20),
              Text('Ride Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: Text("Music Preference"),
                value: _musicPreference,
                onChanged: (bool? value) {
                  setState(() {
                    _musicPreference = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text("Pet Friendly"),
                value: _petFriendly,
                onChanged: (bool? value) {
                  setState(() {
                    _petFriendly = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text("Non-Smoking"),
                value: _nonSmoking,
                onChanged: (bool? value) {
                  setState(() {
                    _nonSmoking = value!;
                  });
                },
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitCarpool,
                child: Text('Register Carpool'),
              ),
            ],
          ),
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
