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
      appBar: AppBar(title: Text('Rate & Review Drivers')),
      body: completedRides.isEmpty
          ? Center(child: Text('No completed rides to rate.'))
          : ListView.builder(
        itemCount: completedRides.length,
        itemBuilder: (context, index) {
          final ride = completedRides[index];
          return ListTile(
            title: Text('Driver: ${ride['driverName']}'),
            subtitle: Text('Carpool ID: ${ride['carpoolID']}'),
            trailing: Icon(Icons.star_border),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RateDriverPage(
                    driverID: ride['driverID'],
                    driverName: ride['driverName'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}