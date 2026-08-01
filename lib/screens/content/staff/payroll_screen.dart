import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/staff_model.dart';
import 'staff_dashboard_screen.dart';

final payrollProvider = FutureProvider.family<List<PayrollRecord>, DateTime>((ref, date) {
  return ref.watch(staffServiceProvider).getMonthlyPayroll(date.month, date.year);
});

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  final DateTime _selectedMonth = DateTime.now();

  Future<void> _payDialog(PayrollRecord payroll) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final accountsRes = await Supabase.instance.client.from('accounts').select('id, name').eq('user_id', userId);
    final accounts = List<Map<String, dynamic>>.from(accountsRes as List);
    
    String? selectedAcc = accounts.isNotEmpty ? accounts.first['id'].toString() : null;
    String method = 'Cash';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pay Salary (Rs. ${payroll.netSalary.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              if (accounts.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedAcc,
                  decoration: const InputDecoration(labelText: 'Deduct from Account', border: OutlineInputBorder()),
                  items: accounts.map((a) => DropdownMenuItem(value: a['id'].toString(), child: Text(a['name']))).toList(),
                  onChanged: (v) => selectedAcc = v,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 48)),
                onPressed: () async {
                  if (selectedAcc == null) return;
                  final service = ref.read(staffServiceProvider);
                  await service.paySalary(
                    payroll: payroll,
                    accountId: selectedAcc!,
                    paymentMethod: method,
                    paidAmount: payroll.netSalary,
                  );
                  ref.invalidate(payrollProvider(_selectedMonth));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final payrollAsync = ref.watch(payrollProvider(_selectedMonth));
    final service = ref.watch(staffServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Payroll (${_selectedMonth.month}/${_selectedMonth.year})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew_rounded),
            onPressed: () async {
              await service.generateMonthlyPayroll(_selectedMonth.month, _selectedMonth.year);
              ref.invalidate(payrollProvider(_selectedMonth));
            },
          )
        ],
      ),
      body: payrollAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await service.generateMonthlyPayroll(_selectedMonth.month, _selectedMonth.year);
                  ref.invalidate(payrollProvider(_selectedMonth));
                },
                icon: const Icon(Icons.flash_on),
                label: const Text('Generate Payroll for this Month'),
              ),
            );
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, idx) {
              final rec = records[idx];
              final isPaid = rec.paymentStatus == PayrollPaymentStatus.paid;

              return ListTile(
                title: Text('Net Salary: Rs. ${rec.netSalary.toStringAsFixed(0)}'),
                subtitle: Text('Basic: Rs. ${rec.basicSalary.toStringAsFixed(0)} | Deductions: Rs. ${rec.advanceDeduction.toStringAsFixed(0)}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaid ? Colors.green : Colors.amber.shade800,
                  ),
                  onPressed: isPaid ? null : () => _payDialog(rec),
                  child: Text(isPaid ? 'PAID' : 'PAY', style: const TextStyle(color: Colors.white)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}