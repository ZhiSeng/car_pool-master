import 'package:flutter/material.dart';
import 'database_helper.dart'; // Ensure correct import for your DatabaseHelper
import 'registered_carpool.dart'; // Import the Registered Carpool screen
import 'carpool_history.dart'; // Import the Carpool History screen

class CarpoolRegistrationPage extends StatefulWidget {
  final int userID;

  // Accept userID passed from CarpoolMainPage
  CarpoolRegistrationPage({required this.userID});

  // Dropdown list for pick-up and drop-off points
  static const List<String> locations = [
    'East Campus Gate',
    'TARUMT Main Gate',
    'PV9',
    'PV15',
    'Setapak Central Mall',
    'PV10',
    'PV12',
  ];

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
  final _carPlateController = TextEditingController(); // Car Plate TextField
  final _carColorController = TextEditingController(); // Car Color TextField
  final _carModelController = TextEditingController(); // Car Model TextField

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

  // Function to handle navigation between pages based on the selected index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
      _dateController.text =
      "${pickedDate.toLocal()}".split(' ')[0]; // YYYY-MM-DD
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
    DateTime selectedDateTime = DateTime(
        now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);

    if (selectedDateTime.isBefore(now)) {
      // Adjust time to future if selected time is in the past
      selectedDateTime = selectedDateTime.add(
          Duration(minutes: 1)); // Add 1 minute to ensure future time

      // Update the time picker to reflect future time
      pickedTime = TimeOfDay.fromDateTime(selectedDateTime);
    }

    setState(() {
      _timeController.text = "${pickedTime.format(context)}"; // HH:MM AM/PM
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
    if (_dateController.text.isEmpty ||
        DateTime.parse(_dateController.text).isBefore(DateTime.now())) {
      return "Please select a future date.";
    }
    if (_timeController.text.isEmpty ||
        DateTime.now().isAfter(DateTime.now().add(Duration(hours: 1)))) {
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationMessage)));
      return;
    }

    if (widget.userID == null) {
      // If userID is not passed or null, show error
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in.")));
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

    final carPlate = _carPlateController.text; // Car Plate number
    final carColor = _carColorController.text; // Car Color
    final carModel = _carModelController.text; // Car Model

    // Prepare data to insert into the database
    Map<String, dynamic> carpoolData = {
      'userID': widget.userID, // Use the passed userID from CarpoolMainPage
      'pickUpPoint': pickUp,
      'dropOffPoint': dropOff,
      'date': date,
      'time': time,
      'availableSeats': seats,
      'ridePreference': preference,
      'status': 'active', // Set it as active
      'carPlateNumber': carPlate, // Store car plate number
      'carColor': carColor, // Store car color
      'carModel': carModel, // Store car model
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
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownSection(
                      'Pick-Up Point', _selectedPickUp, (String? newValue) {
                    setState(() {
                      _selectedPickUp = newValue!;
                    });
                  }),
                  SizedBox(height: 16),
                  _buildDropdownSection(
                      'Drop-Off Point', _selectedDropOff, (String? newValue) {
                    setState(() {
                      _selectedDropOff = newValue!;
                    });
                  }),
                  SizedBox(height: 24),

                  // Date and Time Fields
                  _buildTextFieldWithIcon(
                    controller: _dateController,
                    label: 'Select Date',
                    icon: Icons.calendar_today,
                    onTapIcon: () => _selectDate(context),
                  ),
                  SizedBox(height: 12),
                  _buildTextFieldWithIcon(
                    controller: _timeController,
                    label: 'Select Time',
                    icon: Icons.access_time,
                    onTapIcon: () => _selectTime(context),
                  ),
                  SizedBox(height: 24),

                  // Seat Picker
                  Text('Available Seats:', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: _availableSeats > 1
                            ? () => setState(() => _availableSeats--)
                            : null,
                        color: Colors.blueAccent,
                      ),
                      Text('$_availableSeats',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _availableSeats++),
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Car Info Fields
                  _buildLabel('Car Information'),
                  _buildTextField(
                      _carPlateController, 'Enter Car Plate Number'),
                  _buildTextField(_carColorController, 'Enter Car Color'),
                  _buildTextField(_carModelController, 'Enter Car Model'),
                  SizedBox(height: 24),

                  // Preferences
                  _buildLabel('Ride Preferences'),
                  _buildCheckboxTile(
                      'Music Preference', _musicPreference, (val) {
                    setState(() => _musicPreference = val!);
                  }),
                  _buildCheckboxTile('Pet Friendly', _petFriendly, (val) {
                    setState(() => _petFriendly = val!);
                  }),
                  _buildCheckboxTile('Non-Smoking', _nonSmoking, (val) {
                    setState(() => _nonSmoking = val!);
                  }),
                  SizedBox(height: 30),

                  // Submit Button
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check_circle),
                      label: Text('Register Carpool'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(
                            horizontal: 30, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _submitCarpool,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          : _selectedIndex == 1
          ? RegisteredCarpoolPage(userID: widget.userID)
          : CarpoolHistoryPage(userID: widget.userID),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Register'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Registered'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
  Widget _buildDropdownSection(String label, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: locations.map((location) {
            return DropdownMenuItem(value: location, child: Text(location));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTapIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(icon: Icon(icon), onPressed: onTapIcon),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildCheckboxTile(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blueAccent,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

}