import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/staff_model.dart';
import '../../../widgets/forms/form_widgets.dart';
import 'staff_dashboard_screen.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class AddEditEmployeeScreen extends ConsumerStatefulWidget {
  final Employee? employeeToEdit;

  const AddEditEmployeeScreen({super.key, this.employeeToEdit});

  @override
  ConsumerState<AddEditEmployeeScreen> createState() =>
      _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState
    extends ConsumerState<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _salaryCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _departmentCtrl;

  File? _avatarFile;
  bool _isSaving = false;

  bool get _isEditing => widget.employeeToEdit != null;

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  @override
  void initState() {
    super.initState();
    final emp = widget.employeeToEdit;
    _nameCtrl = TextEditingController(text: emp?.name ?? '');
    _phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    _salaryCtrl = TextEditingController(text: emp?.salary.toString() ?? '0');
    _designationCtrl = TextEditingController(text: emp?.designation ?? '');
    _departmentCtrl =
        TextEditingController(text: emp?.department ?? 'General');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _salaryCtrl.dispose();
    _designationCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final service = ref.read(staffServiceProvider);
    try {
      if (widget.employeeToEdit != null) {
        final updated = Employee(
          id: widget.employeeToEdit!.id,
          userId: widget.employeeToEdit!.userId,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          designation: _designationCtrl.text.trim(),
          department: _departmentCtrl.text.trim(),
          salary: double.parse(_salaryCtrl.text.trim()),
          employmentType: EmploymentType.fullTime,
          status: widget.employeeToEdit!.status,
          joiningDate: widget.employeeToEdit!.joiningDate,
          createdAt: widget.employeeToEdit!.createdAt,
          photoUrl: widget.employeeToEdit!.photoUrl,
        );
        await service.updateEmployee(updated, newAvatarFile: _avatarFile);
      } else {
        final newEmp = Employee(
          id: '',
          userId: '',
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          designation: _designationCtrl.text.trim(),
          department: _departmentCtrl.text.trim(),
          salary: double.parse(_salaryCtrl.text.trim()),
          status: EmploymentStatus.active,
          joiningDate: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await service.addEmployee(newEmp, avatarFile: _avatarFile);
      }

      ref.invalidate(employeesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showFormSnackBar(
          context,
          message: LanguageController.isUrdu ? 'خرابی: $e' : 'Error: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final theme = Theme.of(context);
    final existingPhoto = widget.employeeToEdit?.photoUrl;

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: FormScaffold(
        appBar: formAppBar(
          context,
          title: _isEditing 
              ? (LanguageController.isUrdu ? 'اسٹاف میں ترمیم کریں' : 'Edit Staff') 
              : (LanguageController.isUrdu ? 'اسٹاف شامل کریں' : 'Add Staff'),
          subtitle: _isEditing
              ? (LanguageController.isUrdu ? 'ملازم کا پروفائل اپ ڈیٹ کریں' : 'Update employee profile')
              : (LanguageController.isUrdu ? 'ایک نیا ٹیم ممبر شامل کریں' : 'Add a new team member'),
        ),
        bottomBar: FormBottomBar(
          primaryLabel: _isEditing 
              ? (LanguageController.isUrdu ? 'اسٹاف اپ ڈیٹ کریں' : 'Update Staff') 
              : (LanguageController.isUrdu ? 'اسٹاف محفوظ کریں' : 'Save Staff'),
          primaryIcon: Icons.check_rounded,
          isLoading: _isSaving,
          onPrimary: _isSaving ? null : _save,
          secondaryLabel: LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
          onSecondary: () => Navigator.maybePop(context),
        ),
        children: [
          _isSaving
              ? _buildSkeletonLoadingState(isDark)
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      FormSectionCard(
                        title: LanguageController.isUrdu ? 'پروفাইল فوٹو' : 'Profile photo',
                        subtitle: LanguageController.isUrdu ? 'اس ملازم کے لیے اختیاری تصویر' : 'Optional avatar for this employee',
                        icon: Icons.photo_camera_outlined,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.08),
                                      border: Border.all(
                                        color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.18),
                                        width: 1.5,
                                      ),
                                      image: _avatarFile != null
                                          ? DecorationImage(
                                              image: FileImage(_avatarFile!),
                                              fit: BoxFit.cover,
                                            )
                                          : (existingPhoto != null &&
                                                  existingPhoto.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(existingPhoto),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                    ),
                                    child: (_avatarFile == null &&
                                            (existingPhoto == null ||
                                                existingPhoto.isEmpty))
                                        ? Icon(
                                            Icons.person_outline_rounded,
                                            size: 40,
                                            color: isDark ? jordyBlue : yinMnBlue,
                                          )
                                        : null,
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark ? jordyBlue : yinMnBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? spaceCadet : Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: isDark ? oxfordBlue : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LanguageController.isUrdu ? 'گیلری سے منتخب کرنے کے لیے ٹیپ کریں' : 'Tap to choose from gallery',
                            textAlign: TextAlign.center,
                            textDirection: LanguageController.contentTextDirection,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      FormSectionCard(
                        title: LanguageController.isUrdu ? 'ذاتی تفصیلات' : 'Personal details',
                        subtitle: LanguageController.isUrdu ? 'نام اور رابطہ' : 'Name and contact',
                        icon: Icons.badge_outlined,
                        children: [
                          AppFormTextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            labelText: LanguageController.isUrdu ? 'نام *' : 'Name *',
                            hintText: LanguageController.isUrdu ? 'پورا نام' : 'Full name',
                            prefixIcon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                v == null || v.isEmpty ? (LanguageController.isUrdu ? 'نام درج کریں' : 'Enter name') : null,
                          ),
                          const SizedBox(height: 12),
                          AppFormTextField(
                            controller: _phoneCtrl,
                            labelText: LanguageController.isUrdu ? 'فون' : 'Phone',
                            hintText: '03001234567',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            maxLength: 11,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v != null && v.isNotEmpty && v.length != 11) {
                                return LanguageController.isUrdu ? 'فون نمبر بالکل 11 ہندسوں کا ہونا چاہیے' : 'Phone number must be exactly 11 digits';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      FormSectionCard(
                        title: LanguageController.isUrdu ? 'کردار اور معاوضہ' : 'Role & compensation',
                        subtitle: LanguageController.isUrdu ? 'عہدہ، شعبہ، اور تنخواہ' : 'Job title, department, and salary',
                        icon: Icons.work_outline_rounded,
                        children: [
                          AppFormTextField(
                            controller: _designationCtrl,
                            labelText: LanguageController.isUrdu ? 'عہدہ' : 'Designation',
                            hintText: LanguageController.isUrdu ? 'مثال کے طور پر، سیلز مینیجر' : 'e.g. Sales Manager',
                            prefixIcon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          AppFormTextField(
                            controller: _departmentCtrl,
                            labelText: LanguageController.isUrdu ? 'شعبہ' : 'Department',
                            hintText: LanguageController.isUrdu ? 'مثال کے طور پر، جنرل' : 'e.g. General',
                            prefixIcon: Icons.apartment_outlined,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          AppFormTextField(
                            controller: _salaryCtrl,
                            labelText: LanguageController.isUrdu ? 'ماہانہ تنخواہ (روپے) *' : 'Monthly Salary (Rs.) *',
                            hintText: '0',
                            prefixIcon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            validator: (v) =>
                                v == null || v.isEmpty ? (LanguageController.isUrdu ? 'تنخواہ درج کریں' : 'Enter salary') : null,
                            onFieldSubmitted: (_) => _save(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // Skeleton Loader for Form Submission State
  Widget _buildSkeletonLoadingState(bool isDark) {
    final baseColor = isDark ? spaceCadet.withOpacity(0.4) : lavender.withOpacity(0.6);
    final highlightColor = isDark ? yinMnBlue.withOpacity(0.7) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        final shimmerColor = Color.lerp(baseColor, highlightColor, value)!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(width: 96, height: 96, decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle)),
              const SizedBox(height: 24),
              Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
            ],
          ),
        );
      },
    );
  }
}