import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/staff_model.dart';
import '../../../services/staff_service.dart';
import '../../../widgets/staff/staff_widget.dart';
import 'add_edit_employee_screen.dart';
import 'attendence_screen.dart';
import 'payroll_screen.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

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
    final isDark = ThemeController.isDarkMode;

    return RepaintBoundary(
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.yinMnBlue),
          scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        ),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            title: Text(
              LanguageController.isUrdu ? 'اسٹاف بک' : 'Staff Book',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.oxfordBlue,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                onPressed: () => ref.invalidate(employeesProvider),
              ),
            ],
          ),
          body: empAsync.when(
            data: (employees) {
              final activeCount = employees.where((e) => e.status == EmploymentStatus.active).length;
              final totalSalary = employees.fold(0.0, (sum, e) => sum + e.salary);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: LanguageController.contentTextDirection,
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
                          title: LanguageController.isUrdu ? 'کل اسٹاف' : 'Total Staff',
                          value: '${employees.length}',
                          icon: Icons.people_alt_rounded,
                          color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                        ),
                        StaffMetricCard(
                          title: LanguageController.isUrdu ? 'فعال ملازمین' : 'Active Employees',
                          value: '$activeCount',
                          icon: Icons.check_circle_rounded,
                          color: emerald,
                        ),
                        StaffMetricCard(
                          title: LanguageController.isUrdu ? 'ماہانہ خرچہ' : 'Monthly Expense',
                          value: 'Rs. ${totalSalary.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_rounded,
                          color: Colors.purple.shade400,
                        ),
                        StaffMetricCard(
                          title: LanguageController.isUrdu ? 'زیر التوا پیشگی' : 'Pending Advances',
                          value: 'Rs. ${employees.fold(0.0, (s, e) => s + e.outstandingAdvance).toStringAsFixed(0)}',
                          icon: Icons.money_off_rounded,
                          color: Colors.amber.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Quick Navigation Cards
                    Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark ? AppColors.darkSurface : AppColors.yinMnBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                              side: BorderSide(color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.3) : Colors.transparent),
                            ),
                            onPressed: () => context.push('/staff/attendance'),
                            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                            label: Text(
                              LanguageController.isUrdu ? 'حاضری' : 'Attendance',
                              textDirection: LanguageController.contentTextDirection,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
                              foregroundColor: isDark ? AppColors.oxfordBlue : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                            ),
                            onPressed: () => context.push('/staff/payroll'),
                            icon: Icon(Icons.payments_rounded, color: isDark ? AppColors.oxfordBlue : Colors.white),
                            label: Text(
                              LanguageController.isUrdu ? 'پیرول' : 'Payroll',
                              textDirection: LanguageController.contentTextDirection,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      LanguageController.isUrdu ? 'تمام ملازمین' : 'All Employees',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.oxfordBlue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (employees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            LanguageController.isUrdu ? 'ابھی تک کوئی ملازم شامل نہیں کیا گیا۔' : 'No employees added yet.',
                            textDirection: LanguageController.contentTextDirection,
                            style: TextStyle(
                              color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: employees.length,
                        itemBuilder: (context, idx) {
                          final emp = employees[idx];
                          final designationText = emp.designation ?? (LanguageController.isUrdu ? 'اسٹاف' : 'Staff');
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            elevation: 0,
                            color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              side: BorderSide(
                                color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.15) : AppColors.lavender,
                              ),
                            ),
                            child: ListTile(
                              leading: EmployeeAvatar(name: emp.name, photoUrl: emp.photoUrl),
                              title: Text(
                                emp.name,
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.oxfordBlue,
                                ),
                              ),
                              subtitle: Text(
                                '$designationText • ${emp.department}',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                textDirection: LanguageController.contentTextDirection,
                                children: [
                                  Text(
                                    'Rs. ${emp.salary.toStringAsFixed(0)}',
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.oxfordBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  EmploymentStatusBadge(status: emp.status),
                                ],
                              ),
                              onTap: () => context.push('/staff/add', extra: emp),
                            ),
                          );
                        },
                      ),
                  ],
                ),
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
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
            foregroundColor: isDark ? AppColors.oxfordBlue : Colors.white,
            onPressed: () => context.push('/staff/add'),
            icon: const Icon(Icons.person_add_rounded),
            label: Text(
              LanguageController.isUrdu ? 'ملازم شامل کریں' : 'Add Employee',
              textDirection: LanguageController.contentTextDirection,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // Skeleton Loading Shimmer State
  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : AppColors.lavender.withValues(alpha: 0.6);
    final highlightColor = isDark ? AppColors.yinMnBlue.withValues(alpha: 0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: List.generate(4, (_) => Container(decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xl)))),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: Container(height: 48, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xl)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Container(height: 48, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xl)))),
                ],
              ),
              const SizedBox(height: 30),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  height: 72,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(AppRadius.xl)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}