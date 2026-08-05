import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digital_khata/controller/theme_controller.dart';

// Blue Palette Constants
const Color oxfordBlue = Color(0xFF192338);
const Color spaceCadet = Color(0xFF1E2E4F);
const Color yinMnBlue  = Color(0xFF31487A);
const Color jordyBlue  = Color(0xFF8FB3E2);
const Color lavender   = Color(0xFFD9E1F2);

/// Shared design tokens for all Add/Edit data-entry forms.
class AppFormTokens {
  AppFormTokens._();

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;

  static const double fieldHeight = 56;
  static const double spacingXs = 6;
  static const double spacingSm = 10;
  static const double spacingMd = 16;
  static const double spacingLg = 20;
  static const double spacingXl = 28;

  static const double maxContentWidth = 640;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 12, 20, 24);
  static const EdgeInsets sectionPadding = EdgeInsets.all(18);
}

/// Consistent InputDecoration used across all forms, enhanced with project theme support.
InputDecoration appInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? helperText,
  String? errorText,
  String? prefixText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  int? maxLines,
  bool filled = true,
}) {
  final isDark = ThemeController.isDarkMode;
  final borderRadius = BorderRadius.circular(AppFormTokens.radiusMd);
  final fill = isDark ? spaceCadet.withOpacity(0.6) : const Color(0xFFF1F5F9);

  OutlineInputBorder outline(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    prefixText: prefixText,
    prefixIcon: prefixIcon == null
        ? null
        : IconTheme(
            data: IconThemeData(
              color: isDark ? jordyBlue : yinMnBlue.withOpacity(0.8),
              size: 22,
            ),
            child: prefixIcon,
          ),
    suffixIcon: suffixIcon,
    filled: filled,
    fillColor: fill,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: (maxLines != null && maxLines > 1) ? 16 : 14,
    ),
    labelStyle: TextStyle(
      color: isDark ? jordyBlue : yinMnBlue,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    hintStyle: TextStyle(
      color: isDark ? lavender.withOpacity(0.4) : Colors.grey.shade400,
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
    helperStyle: TextStyle(
      color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
      fontSize: 12,
      height: 1.3,
    ),
    errorStyle: const TextStyle(
      color: Colors.redAccent,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    border: outline(isDark ? jordyBlue.withOpacity(0.2) : Colors.grey.shade300),
    enabledBorder: outline(isDark ? jordyBlue.withOpacity(0.2) : Colors.grey.shade300),
    focusedBorder: outline(isDark ? jordyBlue : yinMnBlue, width: 1.5),
    errorBorder: outline(Colors.red.shade400, width: 1),
    focusedErrorBorder: outline(Colors.red.shade600, width: 1.5),
    disabledBorder: outline(isDark ? jordyBlue.withOpacity(0.1) : Colors.grey.shade200),
  );
}

/// Premium AppBar used on form screens.
PreferredSizeWidget formAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget>? actions,
  bool centerTitle = true,
}) {
  final isDark = ThemeController.isDarkMode;

  return AppBar(
    centerTitle: centerTitle,
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
    titleSpacing: 0,
    title: subtitle == null
        ? Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : oxfordBlue,
            ),
          )
        : Column(
            crossAxisAlignment:
                centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : oxfordBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
    actions: actions,
  );
}

/// Full-screen form shell: dismiss keyboard on tap, scroll, optional sticky actions.
class FormScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final List<Widget> children;
  final Widget? bottomBar;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget? floatingActionButton;

  const FormScaffold({
    super.key,
    this.appBar,
    required this.children,
    this.bottomBar,
    this.isLoading = false,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppFormTokens.maxContentWidth),
        child: SingleChildScrollView(
          padding: padding ??
              EdgeInsets.fromLTRB(
                AppFormTokens.pagePadding.left,
                AppFormTokens.pagePadding.top,
                AppFormTokens.pagePadding.right,
                bottomBar != null ? 12 : 120,
              ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(isDark ? jordyBlue : yinMnBlue),
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: content),
                    if (bottomBar != null) bottomBar!,
                  ],
                ),
        ),
      ),
    );
  }
}

/// Card section used to group related fields.
class FormSectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const FormSectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppFormTokens.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
        border: Border.all(
          color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
        ),
      ),
      child: Padding(
        padding: padding ?? AppFormTokens.sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppFormTokens.radiusSm),
                      ),
                      child: Icon(icon, size: 18, color: isDark ? jordyBlue : yinMnBlue),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : oxfordBlue,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppFormTokens.spacingMd),
            ],
            ..._withGaps(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items) {
    if (items.isEmpty) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) {
        out.add(const SizedBox(height: AppFormTokens.spacingMd));
      }
    }
    return out;
  }
}

/// Sticky bottom action bar for Save / Cancel.
class FormBottomBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? primaryIcon;

  const FormBottomBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? spaceCadet : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? jordyBlue.withOpacity(0.15) : lavender),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppFormTokens.maxContentWidth),
            child: Row(
              children: [
                if (secondaryLabel != null) ...[
                  Expanded(
                    child: FormSecondaryButton(
                      label: secondaryLabel!,
                      onPressed: isLoading ? null : onSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: secondaryLabel != null ? 2 : 1,
                  child: FormPrimaryButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
                    isLoading: isLoading,
                    icon: primaryIcon,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const FormPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? jordyBlue : yinMnBlue,
          foregroundColor: isDark ? oxfordBlue : Colors.white,
          disabledBackgroundColor: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: isDark ? oxfordBlue : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FormSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const FormSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : oxfordBlue,
          side: BorderSide(color: isDark ? jordyBlue.withOpacity(0.35) : yinMnBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Premium text field wrapper with consistent styling.
class AppFormTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const AppFormTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      autofillHints: autofillHints,
      style: TextStyle(
        color: isDark ? Colors.white : oxfordBlue,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 1.25,
      ),
      decoration: appInputDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        maxLines: maxLines,
      ),
    );
  }
}

/// Premium dropdown with matching decoration.
class AppFormDropdown<T> extends StatelessWidget {
  final T? value;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool isExpanded;

  const AppFormDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.validator,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? jordyBlue : yinMnBlue,
      ),
      style: TextStyle(
        color: isDark ? Colors.white : oxfordBlue,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: appInputDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
      dropdownColor: isDark ? spaceCadet : Colors.white,
    );
  }
}

/// Subtle helper / info banner inside forms.
class FormInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const FormInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final accent = color ?? (isDark ? jordyBlue : yinMnBlue);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white : oxfordBlue,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state box used inside forms.
class FormEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const FormEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? spaceCadet.withOpacity(0.4) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
        border: Border.all(color: isDark ? jordyBlue.withOpacity(0.15) : lavender),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: isDark ? jordyBlue.withOpacity(0.7) : yinMnBlue.withOpacity(0.6)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? lavender : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Professional success / error snackbars for forms.
void showFormSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
      ),
      backgroundColor: isError ? Colors.red.shade600 : oxfordBlue,
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Compact section header used between cards when needed.
class FormSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const FormSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : oxfordBlue,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}