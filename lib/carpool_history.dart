import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';  // Ensure correct import for your DatabaseHelper
import 'package:sqflite/sqflite.dart';

class CarpoolHistoryPage extends StatefulWidget {
  final int userID;

  const CarpoolHistoryPage({Key? key, required this.userID}) : super(key: key);

  @override
  _CarpoolHistoryPageState createState() => _CarpoolHistoryPageState();
}

class _CarpoolHistoryPageState extends State<CarpoolHistoryPage> {
  List<Map<String, dynamic>> carpoolHistory = [];

  @override
  void initState() {
    super.initState();
    // Sync history from Firebase to SQLite, then load it from SQLite
    DatabaseHelper.instance.syncCarpoolHistoryFromFirebaseToSQLite().then((_) {
      _loadCarpoolHistory();
    });
  }

  // Method to sync carpool history from Firebase to SQLite

  // Fetch carpool history for the user (completed or canceled)
  Future<void> _loadCarpoolHistory() async {
    final historyData = await DatabaseHelper.instance.getCarpoolHistory(widget.userID);

    setState(() {
      carpoolHistory = historyData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carpool History'),
      ),
      body: carpoolHistory.isEmpty
          ? Center(child: CircularProgressIndicator()) // Show loading indicator when no data
          : ListView.builder(
        itemCount: carpoolHistory.length,
        itemBuilder: (context, index) {
          final carpool = carpoolHistory[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text('${carpool['pickUpPoint']} → ${carpool['dropOffPoint']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${carpool['date']}'),
                  Text('Time: ${carpool['time']}'),
                  Text('Earnings: \$${carpool['earnings']}'),
                ],
              ),
              tileColor: carpool['status'] == 'completed'
                  ? Colors.green[100]
                  : Colors.grey[300],
            ),
          );
        },
      ),
    );
  }
}
