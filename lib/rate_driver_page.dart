import 'package:flutter/material.dart';
import 'database_helper.dart';

class RateDriverPage extends StatefulWidget {
  final int driverID;
  final String driverName;
  final int carpoolID;

  const RateDriverPage({
    super.key,
    required this.driverID,
    required this.driverName,
    required this.carpoolID,
  });

  @override
  _RateDriverPageState createState() => _RateDriverPageState();
}

class _RateDriverPageState extends State<RateDriverPage> {
  int selectedRating = 0;  // Store the selected rating (1-5 stars)
  bool hasRated = false;   // Flag to check if the user has already rated

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRated();
  }

  // Check if the passenger has already rated the driver
  Future<void> _checkIfAlreadyRated() async {
    bool rated = await DatabaseHelper.instance.hasPassengerRatedDriver(
        widget.driverID, widget.driverID, widget.carpoolID);

    setState(() {
      hasRated = rated;
    });
  }

  void _submitRating() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please select a rating before submitting."),
      ));
      return;
    }

    // Save the rating to the database, along with the associated carpoolID
    await DatabaseHelper.instance.submitDriverRating(
        widget.driverID,
        selectedRating.toDouble(),
        widget.carpoolID  // Pass the carpoolID for context
    );

    // Show a success message after submitting the rating
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Thanks for rating ${widget.driverName}!"),
    ));

    // Pop the page and return to the previous screen
    Navigator.pop(context);
  }

  // Function to build the star icons for rating
  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= selectedRating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 36,
      ),
      onPressed: () {
        setState(() {
          selectedRating = index;  // Update selected rating when a star is clicked
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate & Review Page', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Display the driver's name with an icon
            Row(
              children: [
                Icon(Icons.person, size: 30),
                SizedBox(width: 10),
                Text('Driver: ${widget.driverName}', style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 30),

            // Create a row of star buttons for the user to click and rate the driver
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            SizedBox(height: 40),

            // If the passenger has already rated, disable the rating functionality
            ElevatedButton(
              onPressed: hasRated ? null : _submitRating,
              child: Text(hasRated ? "You have already rated this driver" : "Rate", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
