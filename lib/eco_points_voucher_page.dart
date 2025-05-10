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
        final now = DateTime.now();

        availableVouchers = vouchers.where((v) {
          final start = DateTime.tryParse(v['startDate'] ?? '');
          final end = DateTime.tryParse(v['endDate'] ?? '');

          final isWithinDateRange = start != null && end != null && now.isAfter(start.subtract(Duration(days: 1))) && now.isBefore(end.add(Duration(days: 1)));
          final notRedeemed = v['redeemedBy'] == null || v['redeemedBy'] != widget.userID;

          return v['quantity'] > 0 && isWithinDateRange && notRedeemed;
        }).toList();

        redeemedVouchers = vouchers.where((v) => v['redeemedBy'] == widget.userID).toList();
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

    final updatedEcoPoints = ecoPoints - (voucher['ecoPointsRequired'] as int);
    final updatedQuantity = (voucher['quantity'] as int) - 1;

    await DatabaseHelper.instance.updateUserEcoPoints(widget.userID, updatedEcoPoints);

    final updatedVoucher = {
      ...voucher,
      'quantity': updatedQuantity,
      'redeemedBy': widget.userID,
    };

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
