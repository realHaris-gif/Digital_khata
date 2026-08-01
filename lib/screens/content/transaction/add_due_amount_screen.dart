import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:digital_khata/services/services.dart';
import 'package:digital_khata/widgets/forms/form_widgets.dart';
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
      showFormSnackBar(
        context,
        message: 'Please enter valid item name and price',
        isError: true,
      );
      return;
    }

    try {
      await _databaseService.addDueItem(widget.personId, item, price);

      itemController.clear();
      priceController.clear();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        showFormSnackBar(
          context,
          message: 'Due item added successfully',
        );
      }
      await _loadTotals();
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: 'Error adding due item: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> addPayment() async {
    final amount = double.tryParse(paymentController.text.trim()) ?? 0.0;
    final description = paymentDescriptionController.text.trim();

    if (amount <= 0 || amount > _netDue) {
      showFormSnackBar(
        context,
        message: amount <= 0
            ? 'Enter a valid amount'
            : 'Payment cannot exceed net due amount (Rs. ${_netDue.toStringAsFixed(2)})',
        isError: true,
      );
      return;
    }

    try {
      await _databaseService.addPayment(widget.personId, amount, description);

      paymentController.clear();
      paymentDescriptionController.clear();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        showFormSnackBar(
          context,
          message: 'Payment recorded successfully',
        );
      }
      await _loadTotals();
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: 'Error recording payment: $e',
          isError: true,
        );
      }
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
        ),
        title: const Text('Clear / Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormTextField(
              controller: paymentController,
              autofocus: true,
              labelText: 'Amount (Max: Rs. ${_netDue.toStringAsFixed(2)})',
              prefixText: 'Rs. ',
              prefixIcon: Icons.payments_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppFormTextField(
              controller: paymentDescriptionController,
              labelText: 'Description (Optional)',
              prefixIcon: Icons.notes_outlined,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          FormSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          FormPrimaryButton(
            label: 'Record Payment',
            onPressed: addPayment,
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
        ),
        title: const Text('Add Due Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormTextField(
              controller: itemController,
              autofocus: true,
              labelText: 'Item Name',
              hintText: 'What was given?',
              prefixIcon: Icons.shopping_bag_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppFormTextField(
              controller: priceController,
              labelText: 'Price / Amount',
              prefixText: 'Rs. ',
              prefixIcon: Icons.sell_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            Text(
              'Date & Time: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          FormSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          FormPrimaryButton(
            label: 'Add Item',
            icon: Icons.add_rounded,
            onPressed: addDueItem,
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