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

    syncCarpoolHistoryFromFirestoreToSQLite(widget.userID).then((_) {
      // Once the data is synced, you can load it from SQLite
      _loadCarpoolHistory();
    });
  }
  Future<void> syncCarpoolHistoryFromFirestoreToSQLite(int userID) async {
    await DatabaseHelper.instance.syncCarpoolHistoryFromFirestoreToSQLite(userID);
  }

  // Fetch carpool history for the user (completed or canceled)
  Future<void> _loadCarpoolHistory() async {
    final historyData = await DatabaseHelper.instance.getCarpoolHistory(widget.userID);
    print('Fetched carpool history: $historyData');
    setState(() {
      carpoolHistory = historyData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carpool History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // removes the back button
        elevation: 1,
        foregroundColor: Colors.blueAccent,
      ),
      backgroundColor: Color(0xFFF6F8FA),
      body: carpoolHistory.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: carpoolHistory.length,
        itemBuilder: (context, index) {
          final carpool = carpoolHistory[index];
          final status = carpool['status'];
          final isCompleted = status == 'completed';

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Route + Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${carpool['pickUpPoint']} → ${carpool['dropOffPoint']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted ? 'Completed' : 'Canceled',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Row: Date + Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                          SizedBox(width: 6),
                          Text('Date: ${carpool['date']}'),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                          SizedBox(width: 6),
                          Text('Time: ${carpool['time']}'),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Earnings aligned to the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.blueGrey),
                        SizedBox(width: 4),
                        Text(
                          'RM ${double.parse(carpool['earnings'].toString()).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
