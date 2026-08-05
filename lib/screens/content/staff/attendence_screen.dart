import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/staff_model.dart';
import 'staff_dashboard_screen.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  Widget build(BuildContext context) {
    final empAsync = ref.watch(employeesProvider);
    final service = ref.watch(staffServiceProvider);
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
            LanguageController.isUrdu ? 'روزانہ حاضری' : 'Daily Attendance',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          textDirection: LanguageController.contentTextDirection,
          children: [
            // ====================================================
            // HEADER BANNER & DATE SELECTOR CARD
            // ====================================================
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [spaceCadet, yinMnBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: spaceCadet.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Text(
                        LanguageController.isUrdu ? 'آج حاضری لیں' : 'Take attendance today',
                        textDirection: LanguageController.contentTextDirection,
                        style: const TextStyle(
                          color: lavender,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jordyBlue,
                      foregroundColor: oxfordBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Text(
                      LanguageController.isUrdu ? 'تاریخ تبدیل کریں' : 'Change Date',
                      textDirection: LanguageController.contentTextDirection,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // EMPLOYEE ROSTER LIST & STATUS ACTIONS
            // ====================================================
            Expanded(
              child: empAsync.when(
                data: (employees) {
                  if (employees.isEmpty) {
                    return Center(
                      child: Text(
                        LanguageController.isUrdu ? 'کوئی اسٹاف ممبر نہیں ملا' : 'No staff members found',
                        textDirection: LanguageController.contentTextDirection,
                        style: TextStyle(
                          color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: employees.length,
                    itemBuilder: (context, idx) {
                      final emp = employees[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                          ),
                        ),
                        child: Row(
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                                  style: TextStyle(
                                    color: isDark ? jordyBlue : yinMnBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Text(
                                    emp.name,
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : oxfordBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    emp.department,
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: LanguageController.contentTextDirection,
                              children: [
                                IconButton(
                                  tooltip: LanguageController.isUrdu ? 'حاضر نشان زد کریں' : 'Mark Present',
                                  icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
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
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            LanguageController.isUrdu ? 'حاضر نشان زد کر دیا گیا' : 'Marked Present',
                                            textDirection: LanguageController.contentTextDirection,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: LanguageController.isUrdu ? 'غیر حاضری نشان زد کریں' : 'Mark Absent',
                                  icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 28),
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
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            LanguageController.isUrdu ? 'غیر حاضر نشان زد کر دیا گیا' : 'Marked Absent',
                                            textDirection: LanguageController.contentTextDirection,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => _buildSkeletonLoadingState(isDark),
                error: (e, _) => Center(
                  child: Text(
                    LanguageController.isUrdu ? 'خرابی: $e' : 'Error: $e',
                    textDirection: LanguageController.contentTextDirection,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton Shimmer Loading State
  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? spaceCadet.withOpacity(0.4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? jordyBlue.withOpacity(0.1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Container(width: 130, height: 16, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                ),
                Container(width: 70, height: 32, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
        );
      },
    );
  }
}