import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/staff_model.dart';
import '../../../widgets/forms/form_widgets.dart';
import 'staff_dashboard_screen.dart';

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
          message: 'Error: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final existingPhoto = widget.employeeToEdit?.photoUrl;

    return FormScaffold(
      appBar: formAppBar(
        context,
        title: _isEditing ? 'Edit Staff' : 'Add Staff',
        subtitle: _isEditing
            ? 'Update employee profile'
            : 'Add a new team member',
      ),
      bottomBar: FormBottomBar(
        primaryLabel: _isEditing ? 'Update Staff' : 'Save Staff',
        primaryIcon: Icons.check_rounded,
        isLoading: _isSaving,
        onPrimary: _isSaving ? null : _save,
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.maybePop(context),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionCard(
                title: 'Profile photo',
                subtitle: 'Optional avatar for this employee',
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
                              color: cs.primary.withValues(alpha: 0.08),
                              border: Border.all(
                                color: cs.outline.withValues(alpha: 0.18),
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
                                    color: cs.primary,
                                  )
                                : null,
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: cs.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'Tap to choose from gallery',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              FormSectionCard(
                title: 'Personal details',
                subtitle: 'Name and contact',
                icon: Icons.badge_outlined,
                children: [
                  AppFormTextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    labelText: 'Name *',
                    hintText: 'Full name',
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  AppFormTextField(
                    controller: _phoneCtrl,
                    labelText: 'Phone',
                    hintText: '+92 300 1234567',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              FormSectionCard(
                title: 'Role & compensation',
                subtitle: 'Job title, department, and salary',
                icon: Icons.work_outline_rounded,
                children: [
                  AppFormTextField(
                    controller: _designationCtrl,
                    labelText: 'Designation',
                    hintText: 'e.g. Sales Manager',
                    prefixIcon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                  AppFormTextField(
                    controller: _departmentCtrl,
                    labelText: 'Department',
                    hintText: 'e.g. General',
                    prefixIcon: Icons.apartment_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                  AppFormTextField(
                    controller: _salaryCtrl,
                    labelText: 'Monthly Salary (Rs.) *',
                    hintText: '0',
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter salary' : null,
                    onFieldSubmitted: (_) => _save(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
