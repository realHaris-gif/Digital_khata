import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/customer_service.dart';
import '../../services/expense_service.dart';
import '../content/expense/add_expense_screen.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${widget.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
            return const Center(child: CircularProgressIndicator());
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.customerPhone != null &&
                            widget.customerPhone!.isNotEmpty)
                          Text(
                            widget.customerPhone!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Net Due', style: TextStyle(fontSize: 12)),
                        Text(
                          'Rs. ${netDue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: netDue > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Add Expense'),
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
                          _buildSummaryCard(
                              'Total Money Given', totalGiven, Colors.red),
                          _buildSummaryCard(
                              'Total Money Paid', totalPaid, Colors.green),
                          _buildSummaryCard(
                              'Net Receivable Due', netDue, Colors.orange),
                          _buildSummaryCard(
                              'Total Customer Expenses', totalExpenses, Colors.purple),
                        ],
                      ),
                    ),

                    // 2. Transactions Tab Placeholder
                    const Center(
                      child: Text('Transactions recorded for this customer.'),
                    ),

                    // 3. Expenses Tab
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _expenseService.getCustomerExpenses(widget.customerId),
                      builder: (context, expSnapshot) {
                        if (expSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final expenses = expSnapshot.data ?? [];
                        if (expenses.isEmpty) {
                          return const Center(
                            child: Text('No expenses recorded for this customer.'),
                          );
                        }
                        return ListView.builder(
                          itemCount: expenses.length,
                          itemBuilder: (context, i) {
                            final exp = expenses[i];
                            final double expAmount =
                                (exp['amount'] as num?)?.toDouble() ?? 0.0;

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.receipt),
                              ),
                              title: Text(exp['category'] ?? 'General'),
                              subtitle: Text(exp['description'] ?? ''),
                              trailing: Text(
                                'Rs. ${expAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
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
                          return const Center(child: CircularProgressIndicator());
                        }

                        final timeline = timeSnapshot.data ?? [];
                        if (timeline.isEmpty) {
                          return const Center(
                            child: Text('No ledger timeline activity found.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: timeline.length,
                          itemBuilder: (context, i) {
                            final item = timeline[i];
                            final isExpense = item['entryType'] == 'EXPENSE';
                            final double amount =
                                (item['amount'] as num?)?.toDouble() ?? 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  isExpense
                                      ? Icons.receipt_long
                                      : (item['type'] == 'GIVEN'
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward),
                                  color: isExpense
                                      ? Colors.orange
                                      : (item['type'] == 'GIVEN'
                                          ? Colors.red
                                          : Colors.green),
                                ),
                                title: Text(item['title'] ?? ''),
                                subtitle: Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(item['date']),
                                ),
                                trailing: Text(
                                  'Rs. ${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isExpense
                                        ? Colors.orange
                                        : (item['type'] == 'GIVEN'
                                            ? Colors.red
                                            : Colors.green),
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
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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