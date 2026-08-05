import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/customer_service.dart';
import '../../services/expense_service.dart';
import '../content/expense/add_expense_screen.dart';
import 'package:digital_khata/controller/theme_controller.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String? customerPhone;

  const CustomerDetailScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
  }) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExpenseService _expenseService = ExpenseService();

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  void _showDeleteDialog() {
    final isDark = ThemeController.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? spaceCadet : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Customer',
          style: TextStyle(color: isDark ? Colors.white : oxfordBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${widget.customerName}?',
          style: TextStyle(color: isDark ? lavender : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? lavender : Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                await CustomerService.deleteCustomer(widget.customerId);
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer deleted successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete customer: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? spaceCadet : Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: isDark ? jordyBlue : oxfordBlue,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.customerName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              onPressed: _showDeleteDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: isDark ? jordyBlue : yinMnBlue,
            labelColor: isDark ? jordyBlue : yinMnBlue,
            unselectedLabelColor: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Transactions'),
              Tab(text: 'Expenses'),
              Tab(text: 'Statement'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, double>>(
          future: CustomerService.getCustomerSummary(widget.customerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(isDark ? jordyBlue : yinMnBlue),
                ),
              );
            }

            final summary = snapshot.data ?? {};
            final totalGiven = summary['totalGiven'] ?? 0.0;
            final totalPaid = summary['totalPaid'] ?? summary['totalReceived'] ?? 0.0;
            final netDue = summary['netDue'] ?? summary['totalDue'] ?? 0.0;
            final totalExpenses = summary['totalExpenses'] ?? 0.0;

            return Column(
              children: [
                // Top Banner displaying Net Due
                Container(
                  color: isDark ? spaceCadet.withOpacity(0.4) : yinMnBlue.withOpacity(0.06),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customerName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : oxfordBlue,
                            ),
                          ),
                          if (widget.customerPhone != null &&
                              widget.customerPhone!.isNotEmpty)
                            Text(
                              widget.customerPhone!,
                              style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600, fontSize: 13),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Net Due', style: TextStyle(fontSize: 12, color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600)),
                          Text(
                            'Rs. ${netDue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: netDue > 0 ? Colors.red.shade400 : Colors.green.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.add_shopping_cart_rounded, size: 16, color: isDark ? jordyBlue : yinMnBlue),
                          label: Text('Add Expense', style: TextStyle(color: isDark ? jordyBlue : yinMnBlue, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpenseScreen(
                                  initialCustomerId: widget.customerId,
                                  initialCustomerName: widget.customerName,
                                ),
                              ),
                            );
                            if (res == true) _refresh();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: isDark ? jordyBlue.withOpacity(0.4) : yinMnBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Overview Tab
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryCard('Total Money Given', totalGiven, Colors.red.shade400, isDark),
                            _buildSummaryCard('Total Money Paid', totalPaid, Colors.green.shade400, isDark),
                            _buildSummaryCard('Net Receivable Due', netDue, Colors.orange.shade400, isDark),
                            _buildSummaryCard('Total Customer Expenses', totalExpenses, Colors.purple.shade400, isDark),
                          ],
                        ),
                      ),

                      // 2. Transactions Tab Placeholder
                      Center(
                        child: Text(
                          'Transactions recorded for this customer.',
                          style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                        ),
                      ),

                      // 3. Expenses Tab
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _expenseService.getCustomerExpenses(widget.customerId),
                        builder: (context, expSnapshot) {
                          if (expSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(isDark ? jordyBlue : yinMnBlue),
                              ),
                            );
                          }

                          final expenses = expSnapshot.data ?? [];
                          if (expenses.isEmpty) {
                            return Center(
                              child: Text(
                                'No expenses recorded for this customer.',
                                style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: expenses.length,
                            itemBuilder: (context, i) {
                              final exp = expenses[i];
                              final double expAmount =
                                  (exp['amount'] as num?)?.toDouble() ?? 0.0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.receipt_rounded, color: Colors.red.shade400, size: 18),
                                  ),
                                  title: Text(
                                    exp['category'] ?? 'General',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : oxfordBlue),
                                  ),
                                  subtitle: Text(
                                    exp['description'] ?? '',
                                    style: TextStyle(color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    'Rs. ${expAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // 4. Unified Statement Tab
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: CustomerService.getCustomerTimeline(widget.customerId),
                        builder: (context, timeSnapshot) {
                          if (timeSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(isDark ? jordyBlue : yinMnBlue),
                              ),
                            );
                          }

                          final timeline = timeSnapshot.data ?? [];
                          if (timeline.isEmpty) {
                            return Center(
                              child: Text(
                                'No ledger timeline activity found.',
                                style: TextStyle(color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: timeline.length,
                            itemBuilder: (context, i) {
                              final item = timeline[i];
                              final isExpense = item['entryType'] == 'EXPENSE';
                              final double amount =
                                  (item['amount'] as num?)?.toDouble() ?? 0.0;
                              final itemColor = isExpense
                                  ? Colors.orange.shade400
                                  : (item['type'] == 'GIVEN'
                                      ? Colors.red.shade400
                                      : Colors.green.shade400);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: itemColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isExpense
                                          ? Icons.receipt_long_rounded
                                          : (item['type'] == 'GIVEN'
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded),
                                      color: itemColor,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    item['title'] ?? '',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : oxfordBlue),
                                  ),
                                  subtitle: Text(
                                    DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(item['date']),
                                    style: TextStyle(color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    'Rs. ${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: itemColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : oxfordBlue, fontSize: 14),
        ),
        trailing: Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}