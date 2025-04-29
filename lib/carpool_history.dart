import 'package:flutter/material.dart';
import 'database_helper.dart';

class CarpoolHistoryPage extends StatefulWidget {
  const CarpoolHistoryPage({Key? key}) : super(key: key);

  @override
  _CarpoolHistoryPageState createState() => _CarpoolHistoryPageState();
}

class _CarpoolHistoryPageState extends State<CarpoolHistoryPage> {
  List<Map<String, dynamic>> carpoolHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCarpoolHistory();
  }

  Future<void> _loadCarpoolHistory() async {
    int userID = 1;  // Replace with actual userID (get from authentication)
    final historyData = await DatabaseHelper.instance.getCarpoolHistory(userID);

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
          ? Center(child: Text('No carpool history available'))
          : ListView.builder(
        itemCount: carpoolHistory.length,
        itemBuilder: (context, index) {
          final history = carpoolHistory[index];
          return ListTile(
            title: Text('Carpool ID: ${history['carpoolID']}'),
            subtitle: Text('Status: ${history['status']}, Earnings: RM ${history['earnings']}'),
          );
        },
      ),
    );
  }
}
