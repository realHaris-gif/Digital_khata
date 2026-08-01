import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/staff_model.dart';
import '../../../services/staff_service.dart';
import '../../../widgets/staff/staff_widget.dart';
import 'add_edit_employee_screen.dart';
import 'attendence_screen.dart';
import 'payroll_screen.dart';

const emerald = Color(0xFF059669);
final staffServiceProvider = Provider((ref) => StaffService());

final employeesProvider = FutureProvider<List<Employee>>((ref) {
  return ref.watch(staffServiceProvider).getEmployees();
});

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empAsync = ref.watch(employeesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Staff Book', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(employeesProvider),
          ),
        ],
      ),
      body: empAsync.when(
        data: (employees) {
          final activeCount = employees.where((e) => e.status == EmploymentStatus.active).length;
          final totalSalary = employees.fold(0.0, (sum, e) => sum + e.salary);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Dashboard Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StaffMetricCard(
                      title: 'Total Staff',
                      value: '${employees.length}',
                      icon: Icons.people_alt_rounded,
                      color: Colors.blue,
                    ),
                    StaffMetricCard(
                      title: 'Active Employees',
                      value: '$activeCount',
                      icon: Icons.check_circle_rounded,
                      color: emerald,
                    ),
                    StaffMetricCard(
                      title: 'Monthly Expense',
                      value: 'Rs. ${totalSalary.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.purple,
                    ),
                    StaffMetricCard(
                      title: 'Pending Advances',
                      value: 'Rs. ${employees.fold(0.0, (s, e) => s + e.outstandingAdvance).toStringAsFixed(0)}',
                      icon: Icons.money_off_rounded,
                      color: Colors.amber.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Navigation Cards
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                        ),
                        icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                        label: const Text('Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PayrollScreen()),
                        ),
                        icon: const Icon(Icons.payments_rounded, color: Colors.white),
                        label: const Text('Payroll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('All Employees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (employees.isEmpty)
                 const Padding(
  padding: EdgeInsets.all(32),
  child: Center(
    child: Text('No employees added yet.'),
  ),
)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: employees.length,
                    itemBuilder: (context, idx) {
                      final emp = employees[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: EmployeeAvatar(name: emp.name, photoUrl: emp.photoUrl),
                          title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${emp.designation ?? "Staff"} • ${emp.department}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rs. ${emp.salary.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              EmploymentStatusBadge(status: emp.status),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEditEmployeeScreen(employeeToEdit: emp)),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditEmployeeScreen()),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Employee', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}