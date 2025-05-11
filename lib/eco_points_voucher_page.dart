import 'package:flutter/material.dart';
import 'database_helper.dart';

class EcoPointsAndVoucherPage extends StatefulWidget {
  final int userID;

  EcoPointsAndVoucherPage({required this.userID});

  @override
  _EcoPointsAndVoucherPageState createState() => _EcoPointsAndVoucherPageState();
}

class _EcoPointsAndVoucherPageState extends State<EcoPointsAndVoucherPage> {
  int ecoPoints = 0;
  List<Map<String, dynamic>> availableVouchers = [];
  List<Map<String, dynamic>> redeemedVouchers = [];
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await DatabaseHelper.instance.getUserByID(widget.userID);
    final vouchers = await DatabaseHelper.instance.getAllVouchers();

    if (user != null) {
      setState(() {
        currentUser = user;
        ecoPoints = user['ecoPoints'] ?? 0;
        availableVouchers = vouchers.where((v) {
          final redeemedBy = v['redeemedBy'] ?? '';
          final redeemedList = redeemedBy.split(',').map((e) => e.trim()).toList();
          final start = DateTime.tryParse(v['startDate'] ?? '');
          final end = DateTime.tryParse(v['endDate'] ?? '');
          final now = DateTime.now();
          return !redeemedList.contains(widget.userID.toString()) &&
              start != null && end != null &&
              now.isAfter(start) && now.isBefore(end);
        }).toList();

        redeemedVouchers = vouchers.where((v) {
          final redeemedBy = v['redeemedBy'] ?? '';
          return redeemedBy.split(',').map((e) => e.trim()).contains(widget.userID.toString());
        }).toList();
      });
    }
  }

  Future<void> _confirmRedeem(Map<String, dynamic> voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Redemption'),
        content: Text('Do you want to redeem the voucher "${voucher['name']}" for ${voucher['ecoPointsRequired']} points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _redeemVoucher(voucher);
    }
  }

  Future<void> _redeemVoucher(Map<String, dynamic> voucher) async {
    if (ecoPoints < voucher['ecoPointsRequired']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough EcoPoints to redeem this voucher.')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;

    // Get current redeemedBy list
    String redeemedBy = voucher['redeemedBy'] ?? '';
    List<String> redeemedList = redeemedBy.split(',').where((e) => e.trim().isNotEmpty).toList();

    // Prevent double redemption
    if (redeemedList.contains(widget.userID.toString())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already redeemed this voucher.')),
      );
      return;
    }

    // Proceed with redeem
    redeemedList.add(widget.userID.toString());
    final updatedVoucher = {
      ...voucher,
      'redeemedBy': redeemedList.join(','),
    };

    final updatedEcoPoints = ecoPoints - (voucher['ecoPointsRequired'] as int);

    // Update ecoPoints and voucher in DB
    await DatabaseHelper.instance.updateUserEcoPoints(widget.userID, updatedEcoPoints);
    await DatabaseHelper.instance.updateVoucher(voucher['id'], updatedVoucher);

    setState(() {
      ecoPoints = updatedEcoPoints;
      redeemedVouchers.add(updatedVoucher);
      availableVouchers.removeWhere((v) => v['id'] == voucher['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Expanded(child: Text('Voucher "${voucher['name']}" redeemed successfully!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EcoPoints & Vouchers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your EcoPoints: $ecoPoints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Available Vouchers:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: availableVouchers.length,
                itemBuilder: (context, index) {
                  final v = availableVouchers[index];
                  return Card(
                    elevation: 3,
                    child: ListTile(
                      title: Text(v['name'] ?? ''),
                      subtitle: Text('${v['description'] ?? ''}\nPoints: ${v['ecoPointsRequired']}'),
                      trailing: ElevatedButton(
                        onPressed: () => _confirmRedeem(v),
                        child: Text('Redeem'),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Redeemed Vouchers:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: redeemedVouchers.length,
                itemBuilder: (context, index) {
                  final v = redeemedVouchers[index];
                  return Card(
                    color: Colors.green.shade50,
                    elevation: 2,
                    child: ListTile(
                      title: Text(v['name'] ?? ''),
                      subtitle: Text('${v['description'] ?? ''}\nPoints Used: ${v['ecoPointsRequired']}'),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
