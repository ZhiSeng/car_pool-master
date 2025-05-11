import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class CarpoolHistoryPage extends StatefulWidget {
  final int userID;

  const CarpoolHistoryPage({Key? key, required this.userID}) : super(key: key);

  @override
  _CarpoolHistoryPageState createState() => _CarpoolHistoryPageState();
}

class _CarpoolHistoryPageState extends State<CarpoolHistoryPage> {
  List<Map<String, dynamic>> carpoolHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Sync carpool history from Firestore to SQLite, then load it from SQLite
    syncCarpoolHistoryFromFirestoreToSQLite(widget.userID).then((_) {
      _loadCarpoolHistory();
    });
  }

  // Sync carpool history data from Firestore to SQLite
  Future<void> syncCarpoolHistoryFromFirestoreToSQLite(int userID) async {
    await DatabaseHelper.instance.syncCarpoolHistoryFromFirestoreToSQLite(userID);
  }

  // Fetch carpool history for the user (completed or canceled)
  Future<void> _loadCarpoolHistory() async {
    final historyData = await DatabaseHelper.instance.getCarpoolHistory(widget.userID);
    setState(() {
      carpoolHistory = historyData;
      isLoading = false; // Once data is loaded, stop the loading indicator
    });
  }
  Future<void> addCarpoolHistory(int carpoolID, int userID, String status) async {
    final earnings = await DatabaseHelper.instance.calculateCarpoolEarnings(carpoolID);

    // Store carpool history and update earnings in the 'carpools' table
    await DatabaseHelper.instance.addCarpoolHistory(
      carpoolID,
      userID,
      status,
      earnings,
    );

    // Update the earnings in the carpool table
    await DatabaseHelper.instance.updateCarpoolEarnings(carpoolID);

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
        automaticallyImplyLeading: false,
        elevation: 1,
        foregroundColor: Colors.blueAccent,
      ),
      backgroundColor: Color(0xFFF6F8FA),
      body: isLoading
          ? Center(child: CircularProgressIndicator())  // Show loading indicator while syncing
          : carpoolHistory.isEmpty
          ? Center(child: Text('No carpool history available.'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: carpoolHistory.length,
        itemBuilder: (context, index) {
          final carpool = carpoolHistory[index];
          final status = carpool['status'];
          final isCompleted = status == 'completed';
          final carpoolID = carpool['id'];

          return FutureBuilder<double>(
            future: DatabaseHelper.instance.calculateCarpoolEarnings(carpoolID),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text('Loading...'),
                    subtitle: CircularProgressIndicator(),
                  ),
                );
              }

              final earnings = snapshot.data ?? 0.0;

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Earnings: RM ${earnings.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
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
