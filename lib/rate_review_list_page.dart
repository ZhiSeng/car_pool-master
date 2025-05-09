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
  List<Map<String, dynamic>> completedDrivers = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedRides();
  }

  Future<void> _loadCompletedRides() async {
    final result = await DatabaseHelper.instance.getCompletedDriversForRating(widget.userID);
    setState(() {
      completedDrivers = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rate & Review Drivers')),
      body: completedDrivers.isEmpty
          ? Center(child: Text('No completed rides to rate.'))
          : ListView.builder(
        itemCount: completedDrivers.length,
        itemBuilder: (context, index) {
          final ride = completedDrivers[index];
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
