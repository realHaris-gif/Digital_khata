import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/components/my_text_field.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class AddDueAmountScreen extends StatefulWidget {
  final String personId;
  final String personName;

  const AddDueAmountScreen({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  State<AddDueAmountScreen> createState() => _AddDueAmountScreenState();
}

class _AddDueAmountScreenState extends State<AddDueAmountScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController paymentController = TextEditingController();
  final TextEditingController paymentDescriptionController =
      TextEditingController();

  double _totalGiven = 0.0;
  double _totalPaid = 0.0;
  double _netDue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  @override
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    paymentController.dispose();
    paymentDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTotals() async {
    setState(() => _isLoading = true);
    try {
      final totals = await CustomerService.getCustomerTotals(widget.personId);
      if (mounted) {
        setState(() {
          _totalGiven = totals['totalGiven'] ?? totals['totalDue'] ?? 0.0;
          _totalPaid = totals['totalPaid'] ?? totals['totalReceived'] ?? 0.0;
          _netDue = totals['netDue'] ?? (_totalGiven - _totalPaid);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> addDueItem() async {
    final item = itemController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;

    if (item.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid item name and price')),
      );
      return;
    }

    try {
      await _databaseService.addDueItem(widget.personId, item, price);

      itemController.clear();
      priceController.clear();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Due item added successfully')),
        );
      }
      await _loadTotals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding due item: $e')),
        );
      }
    }
  }

  Future<void> addPayment() async {
    final amount = double.tryParse(paymentController.text.trim()) ?? 0.0;
    final description = paymentDescriptionController.text.trim();

    if (amount <= 0 || amount > _netDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            amount <= 0
                ? 'Enter a valid amount'
                : 'Payment cannot exceed net due amount (Rs. ${_netDue.toStringAsFixed(2)})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _databaseService.addPayment(widget.personId, amount, description);

      paymentController.clear();
      paymentDescriptionController.clear();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
      await _loadTotals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording payment: $e')),
        );
      }
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear / Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: paymentController,
              decoration: InputDecoration(
                labelText: 'Amount (Max: Rs. ${_netDue.toStringAsFixed(2)})',
                prefixText: 'Rs. ',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: addPayment,
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Due Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextField(
              controller: itemController,
              hintText: 'Item Name',
              obscureText: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price / Amount',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            Text(
              'Date & Time: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: addDueItem,
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personName),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Net Due Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _netDue > 0
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      border: Border.all(
                        color: _netDue > 0
                            ? Colors.red.shade300
                            : Colors.green.shade300,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Given (Due):',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rs. ${_totalGiven.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Paid (Received):',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rs. ${_totalPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Due Amount:',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. ${_netDue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _netDue > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Clear Due Action Button
                  if (_netDue > 0)
                    SizedBox(
                      width: double.infinity,
                      child: MyButton(
                        text: "Clear Due",
                        onTap: _showPaymentDialog,
                      ),
                    ),

                  const Spacer(),

                  // Operational Summary Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Ledger Balance Status\n\n'
                        'Total Due: Rs. ${_totalGiven.toStringAsFixed(2)}\n'
                        'Total Paid: Rs. ${_totalPaid.toStringAsFixed(2)}\n'
                        'Net Due: Rs. ${_netDue.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Due Item'),
      ),
    );
  }
}