import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'rate_driver_page.dart';

class RateReviewListPage extends StatefulWidget {
  final int userID;

  RateReviewListPage({required this.userID});

  @override
  _RateReviewListPageState createState() => _RateReviewListPageState();
}

class _RateReviewListPageState extends State<RateReviewListPage> {
  List<Map<String, dynamic>> completedRides = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedRides();
  }

  Future<void> _loadCompletedRides() async {
    // Fetch completed rides where the user is the passenger
    final result = await DatabaseHelper.instance.getCompletedRidesForPassenger(widget.userID);
    setState(() {
      completedRides = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate & Review Drivers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: completedRides.isEmpty
          ? Center(child: Text('No completed rides to rate.', style: TextStyle(color: Colors.blueAccent)))
          : ListView.builder(
        itemCount: completedRides.length,
        itemBuilder: (context, index) {
          final ride = completedRides[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.all(16.0),
                title: Text('Driver: ${ride['driverName']}', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Carpool ID: ${ride['carpoolID']}'),
                trailing: Icon(Icons.star_border, color: Colors.blueAccent),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RateDriverPage(
                        driverID: ride['driverID'],
                        driverName: ride['driverName'],
                        carpoolID: ride['carpoolID'],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
