import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class VoucherManagementScreen extends StatefulWidget {
  @override
  _VoucherManagementScreenState createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController pointsCtrl = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController();
  DateTime? startDate, endDate;
  int? editingId;
  String? editingFirestoreId;

  List<Map<String, dynamic>> vouchers = [];

  @override
  void initState() {
    super.initState();
    loadVouchers();
  }

  Future<void> loadVouchers() async {
    final data = await DatabaseHelper.instance.getAllVouchers();
    setState(() => vouchers = data);
  }

  Future<void> saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates.')),
      );
      return;
    }

    if (startDate!.isBefore(now.subtract(Duration(days: 1))) || endDate!.isBefore(now.subtract(Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dates cannot be before today.')),
      );
      return;
    }

    if (startDate!.difference(endDate!).inDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start and end dates cannot be the same day.')),
      );
      return;
    }

    final voucher = {
      'name': nameCtrl.text,
      'description': descCtrl.text,
      'ecoPointsRequired': int.tryParse(pointsCtrl.text) ?? 0,
      'quantity': int.tryParse(quantityCtrl.text) ?? 0,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };

    if (editingId != null) {
      voucher['firestoreID'] = editingFirestoreId;
      await DatabaseHelper.instance.updateVoucher(editingId!, voucher);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher updated successfully.')),
      );
    } else {
      await DatabaseHelper.instance.insertVoucher(voucher);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher added successfully.')),
      );
    }

    clearForm();
    await loadVouchers();
  }

  void clearForm() {
    nameCtrl.clear();
    descCtrl.clear();
    pointsCtrl.clear();
    quantityCtrl.clear();
    startDate = null;
    endDate = null;
    editingId = null;
    editingFirestoreId = null;
  }

  void loadForEdit(Map<String, dynamic> v) {
    setState(() {
      nameCtrl.text = v['name'];
      descCtrl.text = v['description'];
      pointsCtrl.text = v['ecoPointsRequired'].toString();
      quantityCtrl.text = v['quantity'].toString();
      startDate = DateTime.tryParse(v['startDate'] ?? '');
      endDate = DateTime.tryParse(v['endDate'] ?? '');
      editingId = v['id'];
      editingFirestoreId = v['firestoreID'];
    });
  }

  Future<void> deleteVoucher(int id, String firestoreID) async {
    await DatabaseHelper.instance.deleteVoucher(id, firestoreID);
    await loadVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voucher Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: 'Voucher Name'),
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: 'Description'),
                    validator: (v) => v!.isEmpty ? 'Enter description' : null,
                  ),
                  TextFormField(
                    controller: pointsCtrl,
                    decoration: InputDecoration(labelText: 'EcoPoints Required'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Enter points' : null,
                  ),
                  TextFormField(
                    controller: quantityCtrl,
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Enter quantity' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => startDate = picked);
                          },
                          child: Text(startDate == null
                              ? 'Select Start Date'
                              : 'Start: ${DateFormat.yMd().format(startDate!)}'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => endDate = picked);
                          },
                          child: Text(endDate == null
                              ? 'Select End Date'
                              : 'End: ${DateFormat.yMd().format(endDate!)}'),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: saveVoucher,
                    child: Text(editingId != null ? 'Update' : 'Add Voucher'),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: vouchers.length,
                itemBuilder: (context, index) {
                  final v = vouchers[index];
                  return ListTile(
                    title: Text(v['name'] ?? ''),
                    subtitle: Text('${v['description'] ?? ''} \nPoints: ${v['ecoPointsRequired']}\nQuantity: ${v['quantity']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => loadForEdit(v),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteVoucher(v['id'], v['firestoreID']),
                        ),
                      ],
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
