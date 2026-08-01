import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/staff_model.dart';
import 'staff_dashboard_screen.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final empAsync = ref.watch(employeesProvider);
    final service = ref.watch(staffServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Attendance')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2025),
            lastDate: DateTime(2030),
            onDateChanged: (d) => setState(() => _selectedDate = d),
          ),
          const Divider(),
          Expanded(
            child: empAsync.when(
              data: (employees) {
                return ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, idx) {
                    final emp = employees[idx];
                    return ListTile(
                      title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(emp.department),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            onPressed: () async {
                              await service.markAttendance(
                                Attendance(
                                  id: '',
                                  employeeId: emp.id,
                                  userId: '',
                                  date: _selectedDate,
                                  status: AttendanceStatus.present,
                                ),
                              );
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked Present')));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () async {
                              await service.markAttendance(
                                Attendance(
                                  id: '',
                                  employeeId: emp.id,
                                  userId: '',
                                  date: _selectedDate,
                                  status: AttendanceStatus.absent,
                                ),
                              );
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked Absent')));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}