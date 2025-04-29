import 'package:flutter/material.dart';
import 'database_helper.dart';

class RateDriverPage extends StatefulWidget {
  final int driverID;
  final String driverName;

  const RateDriverPage({super.key, required this.driverID, required this.driverName});

  @override
  _RateDriverPageState createState() => _RateDriverPageState();
}

class _RateDriverPageState extends State<RateDriverPage> {
  int selectedRating = 0;

  void _submitRating() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please select a rating before submitting."),
      ));
      return;
    }

    await DatabaseHelper.instance.submitDriverRating(widget.driverID, selectedRating.toDouble());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Thanks for rating ${widget.driverName}!"),
    ));

    Navigator.pop(context);
  }

  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= selectedRating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 36,
      ),
      onPressed: () {
        setState(() {
          selectedRating = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate & Review Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 30),
                SizedBox(width: 10),
                Text('Driver: ${widget.driverName}', style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitRating,
              child: Text("Rate"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
