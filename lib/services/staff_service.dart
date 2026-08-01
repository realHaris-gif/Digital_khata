import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff_model.dart';

class StaffService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser?.id ?? '';

  // ---------------------------------------------------------
  // EMPLOYEE CRUD & STORAGE
  // ---------------------------------------------------------

  Future<List<Employee>> getEmployees() async {
    final res = await _client
        .from('employees')
        .select()
        .eq('user_id', _userId)
        .order('name', ascending: true);
    return (res as List).map((e) => Employee.fromJson(e)).toList();
  }

  Future<String?> uploadAvatar(File file, String empId) async {
    final fileName = '$empId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'avatars/$fileName';
    await _client.storage.from('staff_avatars').upload(path, file);
    return _client.storage.from('staff_avatars').getPublicUrl(path);
  }

  Future<void> addEmployee(Employee emp, {File? avatarFile}) async {
    String? photoUrl;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    if (avatarFile != null) {
      photoUrl = await uploadAvatar(avatarFile, tempId);
    }

    final data = emp.toJson();
    data['user_id'] = _userId;
    data['photo_url'] = photoUrl;
    data.remove('id');

    await _client.from('employees').insert(data);
  }

  Future<void> updateEmployee(Employee emp, {File? newAvatarFile}) async {
    String? photoUrl = emp.photoUrl;
    if (newAvatarFile != null) {
      photoUrl = await uploadAvatar(newAvatarFile, emp.id);
    }

    final data = emp.toJson();
    data['photo_url'] = photoUrl;

    await _client.from('employees').update(data).eq('id', emp.id);
  }

  Future<void> toggleEmployeeStatus(String empId, EmploymentStatus status) async {
    await _client
        .from('employees')
        .update({'status': status.name}).eq('id', empId);
  }

  // ---------------------------------------------------------
  // ATTENDANCE & LEAVE MANAGERS
  // ---------------------------------------------------------

  Future<List<Attendance>> getDailyAttendance(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final res = await _client
        .from('attendance')
        .select()
        .eq('user_id', _userId)
        .eq('date', dateStr);
    return (res as List).map((e) => Attendance.fromJson(e)).toList();
  }

  Future<void> markAttendance(Attendance att) async {
    final data = att.toJson();
    data['user_id'] = _userId;
    data.remove('id');

    await _client.from('attendance').upsert(data, onConflict: 'employee_id, date');
  }

  Future<void> applyLeave(LeaveRequest req) async {
    final data = req.toJson();
    data['user_id'] = _userId;
    data.remove('id');
    await _client.from('leave_requests').insert(data);
  }

  Future<void> updateLeaveStatus(String leaveId, String empId, LeaveStatus status, DateTime start, DateTime end) async {
    await _client.from('leave_requests').update({
      'status': status.name,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', leaveId);

    // Automatically mark attendance as LEAVE if approved
    if (status == LeaveStatus.approved) {
      for (var d = start; d.isBefore(end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        await markAttendance(
          Attendance(
            id: '',
            employeeId: empId,
            userId: _userId,
            date: d,
            status: AttendanceStatus.leave,
            notes: 'Approved Leave',
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------
  // PAYROLL & CASHBOOK / ACCOUNTS INTEGRATION
  // ---------------------------------------------------------

  Future<List<PayrollRecord>> getMonthlyPayroll(int month, int year) async {
    final res = await _client
        .from('payroll')
        .select()
        .eq('user_id', _userId)
        .eq('month', month)
        .eq('year', year);
    return (res as List).map((e) => PayrollRecord.fromJson(e)).toList();
  }

  Future<void> generateMonthlyPayroll(int month, int year) async {
    final employees = await getEmployees();
    for (var emp in employees) {
      if (emp.status != EmploymentStatus.active) continue;

      final netSalary = emp.salary - emp.outstandingAdvance;
      await _client.from('payroll').upsert({
        'user_id': _userId,
        'employee_id': emp.id,
        'month': month,
        'year': year,
        'basic_salary': emp.salary,
        'advance_deduction': emp.outstandingAdvance,
        'net_salary': netSalary < 0 ? 0.0 : netSalary,
        'payment_status': 'pending',
      }, onConflict: 'employee_id, month, year');
    }
  }

  Future<void> paySalary({
    required PayrollRecord payroll,
    required String accountId,
    required String paymentMethod,
    required double paidAmount,
  }) async {
    // 1. Update Payroll Status
    await _client.from('payroll').update({
      'payment_status': 'paid',
      'paid_date': DateTime.now().toIso8601String(),
      'payment_method': paymentMethod,
      'account_id': accountId,
    }).eq('id', payroll.id);

    // 2. Deduct from Accounts table balance
    final accRes = await _client.from('accounts').select('balance').eq('id', accountId).single();
    final currentBal = (accRes['balance'] as num).toDouble();
    await _client
        .from('accounts')
        .update({'balance': currentBal - paidAmount}).eq('id', accountId);

    // 3. Post to Cash Book Expenses
    await _client.from('expenses').insert({
      'user_id': _userId,
      'category': 'Salaries',
      'amount': paidAmount,
      'description': 'Salary Payment for ${payroll.month}/${payroll.year}',
      'date': DateTime.now().toIso8601String(),
    });
  }
}