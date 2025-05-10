import 'package:flutter/material.dart';
import 'available_rides.dart';
import 'package:car_pool/carpool_registration.dart';

class FindARidePage extends StatefulWidget {
  final int userID;

  const FindARidePage({
    required this.userID,
  });

  @override
  _FindARidePageState createState() => _FindARidePageState();
}

class _FindARidePageState extends State<FindARidePage> {
  // Controller for Seat Needed
  int seatCount = 1;

  // Dropdown values for "From" and "To"
  String? fromLocation;
  String? toLocation;

  // Preferences checkboxes
  bool musicPreference = false;
  bool petFriendly = false;
  bool nonSmoking = false;

  // List of locations for the dropdown
  // final List<String> locations = ['Location A', 'Location B', 'Location C', 'Location D', 'TARUMT Main Gate', 'TARUMT East Campus'];
  final List<String> locations = CarpoolRegistrationPage.locations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find a Ride', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // From Dropdown with Decoration
              _buildLocationDropdown('Pickup Location', fromLocation, (value) {
                setState(() {
                  fromLocation = value;
                });
              }),

              SizedBox(height: 20),

              // To Dropdown with Decoration
              _buildLocationDropdown('Dropoff Location', toLocation, (value) {
                setState(() {
                  toLocation = value;
                });
              }),

              SizedBox(height: 30),

              // Ride Preferences Section
              Text(
                'Ride Preferences',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),

              // Preferences Checkboxes
              _buildCheckboxListTile('Music Preference', musicPreference, (value) {
                setState(() {
                  musicPreference = value!;
                });
              }),
              _buildCheckboxListTile('Pet Friendly', petFriendly, (value) {
                setState(() {
                  petFriendly = value!;
                });
              }),
              _buildCheckboxListTile('Non-Smoking', nonSmoking, (value) {
                setState(() {
                  nonSmoking = value!;
                });
              }),

              SizedBox(height: 30),

              // Seat Needed Section
              Text(
                'Seats Needed: $seatCount',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),

              // Seat Picker with decoration
              _buildSeatPicker(),

              SizedBox(height: 30),

              // Find Ride Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Call validation before proceeding
                    _validateLocations();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text('Find Ride'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Dropdown Widget with Decoration
  Widget _buildLocationDropdown(String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The actual dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: label, // Always show the label
                labelStyle: TextStyle(
                  fontSize: 18, // Increased font size for label
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: selectedValue == null
                        ? Colors.blueAccent // Default border color
                        : Colors.greenAccent, // Change to highlight color when selected
                    width: 2, // Border width
                  ),
                ),
                // Placeholder text when no value is selected
                hintText: 'Select a location',
                hintStyle: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              child: DropdownButton<String>(
                value: selectedValue ?? null, // Default value is null if no location is selected
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    onChanged(value);
                  });
                },
                items: [
                  ...locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Colors.black, // Use black text color for all items
                          fontWeight: location == selectedValue ? FontWeight.bold : FontWeight.normal, // Bold for selected item
                        ),
                      ),
                    );
                  }).toList(),
                ],
                isDense: true,
                iconSize: 24,
                underline: SizedBox(), // Remove underline
                style: TextStyle(color: Colors.black), // Default color for selected value when closed
                hint: Text('Select a location'), // Adding a hint text in case the value is null
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show Snackbar alerting the user
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Validate if the "From" and "To" locations are null
  void _validateLocations() {
    if (fromLocation == null && toLocation == null) {
      _showSnackbar('Please select both pickup and dropoff locations.');
    } else if (fromLocation == null) {
      _showSnackbar('Please select a pickup location.');
    } else if (toLocation == null) {
      _showSnackbar('Please select a dropoff location.');
    } else if (fromLocation == toLocation) {
      _showSnackbar('Pickup and Dropoff locations cannot be the same.');
    } else {
      // Navigate to the available rides page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AvailableRidesPage(
            fromLocation: fromLocation!,
            toLocation: toLocation!,
            seatCount: seatCount,
            musicPreference: musicPreference,
            petFriendly: petFriendly,
            nonSmoking: nonSmoking,
            userID: widget.userID,
          ),
        ),
      );
    }
  }

  // Custom Checkbox Widget
  Widget _buildCheckboxListTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: CheckboxListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
        tileColor: Colors.white,
        checkColor: Colors.white,
        activeColor: Colors.blueAccent,
      ),
    );
  }

  // Seat Picker Widget
  Widget _buildSeatPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline),
          onPressed: seatCount > 1
              ? () {
            setState(() {
              seatCount--;
            });
          }
              : null,
          color: Colors.blueAccent,
          iconSize: 30,
        ),
        Text(
          '$seatCount',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline),
          onPressed: seatCount < 4
              ? () {
            setState(() {
              seatCount++;
            });
          }
              : null,
          color: Colors.blueAccent,
          iconSize: 30,
        ),
      ],
    );
  }
}
