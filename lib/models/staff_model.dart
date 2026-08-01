import 'package:equatable/equatable.dart';

enum EmploymentStatus { active, inactive, terminated }
enum EmploymentType { fullTime, partTime, contract, freelance }
enum AttendanceStatus { present, absent, halfDay, leave, late }
enum LeaveType { sick, casual, annual, unpaid, custom }
enum LeaveStatus { pending, approved, rejected }
enum PayrollPaymentStatus { pending, paid, partiallyPaid }

class Employee extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? email;
  final String? cnic;
  final String? address;
  final String? designation;
  final String department;
  final DateTime joiningDate;
  final double salary;
  final EmploymentType employmentType;
  final EmploymentStatus status;
  final String? photoUrl;
  final String? notes;
  final double outstandingAdvance;
  final DateTime createdAt;

  const Employee({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.cnic,
    this.address,
    this.designation,
    this.department = 'General',
    required this.joiningDate,
    required this.salary,
    this.employmentType = EmploymentType.fullTime,
    this.status = EmploymentStatus.active,
    this.photoUrl,
    this.notes,
    this.outstandingAdvance = 0.0,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      cnic: json['cnic'] as String?,
      address: json['address'] as String?,
      designation: json['designation'] as String?,
      department: json['department'] as String? ?? 'General',
      joiningDate: DateTime.parse(json['joining_date'] as String),
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      employmentType: EmploymentType.values.firstWhere(
        (e) => e.name == json['employment_type'],
        orElse: () => EmploymentType.fullTime,
      ),
      status: EmploymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EmploymentStatus.active,
      ),
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      outstandingAdvance: (json['outstanding_advance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'cnic': cnic,
        'address': address,
        'designation': designation,
        'department': department,
        'joining_date': joiningDate.toIso8601String().split('T')[0],
        'salary': salary,
        'employment_type': employmentType.name,
        'status': status.name,
        'photo_url': photoUrl,
        'notes': notes,
        'outstanding_advance': outstandingAdvance,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phone,
        email,
        cnic,
        address,
        designation,
        department,
        joiningDate,
        salary,
        employmentType,
        status,
        photoUrl,
        notes,
        outstandingAdvance,
        createdAt,
      ];
}

class Attendance extends Equatable {
  final String id;
  final String employeeId;
  final String userId;
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final double workingHours;
  final double overtimeHours;
  final AttendanceStatus status;
  final String? notes;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.workingHours = 0.0,
    this.overtimeHours = 0.0,
    required this.status,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
      workingHours: (json['working_hours'] as num?)?.toDouble() ?? 0.0,
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'user_id': userId,
        'date': date.toIso8601String().split('T')[0],
        'check_in': checkIn,
        'check_out': checkOut,
        'working_hours': workingHours,
        'overtime_hours': overtimeHours,
        'status': status.name,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        employeeId,
        userId,
        date,
        checkIn,
        checkOut,
        workingHours,
        overtimeHours,
        status,
        notes,
      ];
}

class LeaveRequest extends Equatable {
  final String id;
  final String employeeId;
  final String userId;
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final LeaveStatus status;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.status,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      userId: json['user_id'] as String,
      leaveType: LeaveType.values.firstWhere(
        (e) => e.name == json['leave_type'],
        orElse: () => LeaveType.casual,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String?,
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'user_id': userId,
        'leave_type': leaveType.name,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'reason': reason,
        'status': status.name,
      };

  @override
  List<Object?> get props => [id, employeeId, userId, leaveType, startDate, endDate, reason, status];
}

class PayrollRecord extends Equatable {
  final String id;
  final String employeeId;
  final String userId;
  final int month;
  final int year;
  final double basicSalary;
  final double allowances;
  final double bonuses;
  final double deductions;
  final double overtimeAmount;
  final double advanceDeduction;
  final double netSalary;
  final PayrollPaymentStatus paymentStatus;
  final DateTime? paidDate;
  final String paymentMethod;
  final String? accountId;

  const PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.userId,
    required this.month,
    required this.year,
    required this.basicSalary,
    this.allowances = 0.0,
    this.bonuses = 0.0,
    this.deductions = 0.0,
    this.overtimeAmount = 0.0,
    this.advanceDeduction = 0.0,
    required this.netSalary,
    this.paymentStatus = PayrollPaymentStatus.pending,
    this.paidDate,
    this.paymentMethod = 'Cash',
    this.accountId,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      userId: json['user_id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      basicSalary: (json['basic_salary'] as num).toDouble(),
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      overtimeAmount: (json['overtime_amount'] as num?)?.toDouble() ?? 0.0,
      advanceDeduction: (json['advance_deduction'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['net_salary'] as num).toDouble(),
      paymentStatus: PayrollPaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PayrollPaymentStatus.pending,
      ),
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date'] as String) : null,
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      accountId: json['account_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        userId,
        month,
        year,
        basicSalary,
        allowances,
        bonuses,
        deductions,
        overtimeAmount,
        advanceDeduction,
        netSalary,
        paymentStatus,
        paidDate,
        paymentMethod,
        accountId,
      ];
}